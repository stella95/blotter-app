require 'rails_helper'

RSpec.describe Portfolio do
  describe "associations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to have_many(:entries).dependent(:destroy) }
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
end
