require "rails_helper"

RSpec.describe NightlySnapshotJob do
  it "records market value, average cost basis, cash flow, and unpriced count per currency" do
    portfolio = create(:portfolio)
    asset = create(:asset, currency: "EUR")
    create(:asset_price, asset:, price: 120, as_of: 1.day.ago)
    create(:entry_line_item, entry: create(:entry, portfolio:), asset:, quantity: 5, price_per_unit: 100, amount: -500)
    create(:entry_line_item, :sell, entry: create(:entry, portfolio:), asset:, quantity: 2, price_per_unit: 110, amount: 220)
    create(:entry_line_item, action: :deposit, entry: create(:entry, portfolio:), asset:, quantity: 0, amount: 1000)
    create(:entry_line_item, action: :withdrawal, entry: create(:entry, portfolio:), asset:, quantity: 0, amount: -200)

    described_class.new.perform

    snapshot = PortfolioSnapshot.find_by(portfolio:, currency: "EUR")
    expect(snapshot.total_market_value).to eq(360) # 3 held * 120
    expect(snapshot.total_cost_basis).to eq(300)    # avg cost 100 * 3 held
    expect(snapshot.net_cash_flow_to_date).to eq(800) # 1000 - 200
    expect(snapshot.unpriced_assets_count).to eq(0)
  end

  it "skips a currency the portfolio no longer holds anything in" do
    portfolio = create(:portfolio)
    asset = create(:asset, currency: "USD")
    entry = create(:entry, portfolio:)
    create(:entry_line_item, entry:, asset:, quantity: 2, price_per_unit: 100, amount: -200)
    create(:entry_line_item, :sell, entry:, asset:, quantity: 2, price_per_unit: 100, amount: 200)

    described_class.new.perform

    expect(PortfolioSnapshot.where(portfolio:)).to be_empty
  end

  it "updates today's row instead of duplicating it on a second run" do
    portfolio = create(:portfolio)
    asset = create(:asset, currency: "EUR")
    create(:asset_price, asset:, price: 100, as_of: 1.day.ago)
    create(:entry_line_item, entry: create(:entry, portfolio:), asset:, quantity: 1, price_per_unit: 90, amount: -90)

    described_class.new.perform
    described_class.new.perform

    expect(PortfolioSnapshot.where(portfolio:, currency: "EUR").count).to eq(1)
  end

  it "ignores an archived portfolio" do
    portfolio = create(:portfolio).tap(&:archive!)
    asset = create(:asset)
    create(:entry_line_item, entry: create(:entry, portfolio:), asset:, quantity: 1, price_per_unit: 90, amount: -90)

    described_class.new.perform

    expect(PortfolioSnapshot.where(portfolio:)).to be_empty
  end
end
