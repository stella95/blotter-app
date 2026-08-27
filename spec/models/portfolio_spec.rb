require 'rails_helper'

RSpec.describe Portfolio do
  describe "associations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to have_many(:entries).dependent(:restrict_with_error) }
    it { is_expected.to have_many(:entry_line_items).through(:entries) }
    it { is_expected.to have_many(:portfolio_snapshots).dependent(:destroy) }
  end

  describe "validations" do
    subject { build(:portfolio) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:name).scoped_to(:user_id).case_insensitive }

    it "lets two users each have a portfolio of the same name" do
      create(:portfolio, user: create(:user), name: "Retirement")

      expect(build(:portfolio, user: create(:user), name: "Retirement")).to be_valid
    end

    it "defaults to EUR" do
      expect(described_class.new.currency).to eq("EUR")
    end

    it "normalizes the currency code" do
      expect(create(:portfolio, currency: " usd ").currency).to eq("USD")
    end
  end

  describe "#currencies_held" do
    it "reads currency off whatever is actually held, a portfolio has none of its own" do
      portfolio = create(:portfolio)
      eur_asset = create(:asset, currency: "EUR")
      usd_asset = create(:asset, currency: "USD")
      create(:entry_line_item, entry: create(:entry, portfolio:), asset: eur_asset, quantity: 1, price_per_unit: 10, amount: -10)
      create(:entry_line_item, entry: create(:entry, portfolio:), asset: usd_asset, quantity: 1, price_per_unit: 10, amount: -10)

      expect(portfolio.currencies_held).to contain_exactly("EUR", "USD")
    end

    it "is empty for a portfolio with no holdings" do
      expect(create(:portfolio).currencies_held).to eq([])
    end
  end

  describe "archiving" do
    it "is a soft close that leaves history intact" do
      portfolio = create(:portfolio)
      create(:entry, portfolio:)

      portfolio.archive!

      expect(portfolio).to be_archived
      expect(portfolio.entries.count).to eq(1)
    end

    it "drops out of the active scope" do
      live = create(:portfolio)
      create(:portfolio).archive!

      expect(described_class.active).to contain_exactly(live)
    end
  end

  describe "#current_holdings" do
    it "sums signed quantity across buys and sells, valued at the latest price" do
      portfolio = create(:portfolio)
      asset = create(:asset)
      create(:asset_price, asset:, price: 110, as_of: 1.day.ago)
      entry = create(:entry, portfolio:)
      create(:entry_line_item, :sell, entry:, asset:, quantity: 2)
      create(:entry_line_item, entry:, asset:, quantity: 5, price_per_unit: 100, amount: -500)

      holdings = portfolio.current_holdings

      expect(holdings.size).to eq(1)
      expect(holdings.first.quantity).to eq(3)
      expect(holdings.first.value).to eq(330)
    end

    it "excludes a position that has been fully closed out" do
      portfolio = create(:portfolio)
      asset = create(:asset)
      entry = create(:entry, portfolio:)
      create(:entry_line_item, entry:, asset:, quantity: 2, price_per_unit: 100, amount: -200)
      create(:entry_line_item, :sell, entry:, asset:, quantity: 2, price_per_unit: 100, amount: 200)

      expect(portfolio.current_holdings).to be_empty
    end

    it "is nil for value when there is no price yet" do
      portfolio = create(:portfolio)
      asset = create(:asset)
      create(:entry_line_item, entry: create(:entry, portfolio:), asset:, quantity: 1, price_per_unit: 50, amount: -50)

      holding = portfolio.current_holdings.first

      expect(holding.price).to be_nil
      expect(holding.value).to be_nil
    end
  end

  describe "deletion" do
    it "is blocked once the portfolio has entries" do
      portfolio = create(:portfolio)
      create(:entry, portfolio:)

      expect(portfolio.destroy).to be false
      expect(portfolio.errors[:base]).to be_present
    end

    it "is allowed for a portfolio with no history" do
      expect(create(:portfolio).destroy).to be_truthy
    end
  end
end
