require 'rails_helper'

RSpec.describe PortfolioSnapshot do
  it { is_expected.to belong_to(:portfolio) }

  describe "uniqueness" do
    # One row per portfolio per currency per day. A portfolio holding both EUR
    # and USD positions has no single correct total, so it gets two rows.
    it "allows one row per currency on the same day" do
      portfolio = create(:portfolio)
      create(:portfolio_snapshot, portfolio:, currency: "EUR", captured_on: Date.current)

      expect(build(:portfolio_snapshot, portfolio:, currency: "USD", captured_on: Date.current))
        .to be_valid
    end

    it "refuses a second row for the same currency and day" do
      portfolio = create(:portfolio)
      create(:portfolio_snapshot, portfolio:, currency: "EUR", captured_on: Date.current)

      expect(build(:portfolio_snapshot, portfolio:, currency: "EUR", captured_on: Date.current))
        .not_to be_valid
    end
  end

  describe "#complete?" do
    it "is true when every held asset had a price" do
      expect(build(:portfolio_snapshot, unpriced_assets_count: 0)).to be_complete
    end

    # Manual price entry means this will happen often, and the interface needs
    # to admit it rather than present a total it cannot stand behind.
    it "is false when some asset had no price at all" do
      expect(build(:portfolio_snapshot, :incomplete)).not_to be_complete
    end
  end

  describe "scopes" do
    it "filters by currency and orders chronologically" do
      portfolio = create(:portfolio)
      older = create(:portfolio_snapshot, portfolio:, currency: "EUR", captured_on: 3.days.ago)
      newer = create(:portfolio_snapshot, portfolio:, currency: "EUR", captured_on: 1.day.ago)
      create(:portfolio_snapshot, portfolio:, currency: "USD", captured_on: 2.days.ago)

      expect(described_class.in_currency("eur").chronological).to eq([ older, newer ])
    end
  end
end
