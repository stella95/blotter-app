require 'rails_helper'

RSpec.describe Entry do
  describe "associations" do
    it { is_expected.to belong_to(:portfolio) }
    it { is_expected.to have_many(:entry_line_items).dependent(:destroy) }
  end

  describe "occurred_on" do
    it { is_expected.to validate_presence_of(:occurred_on) }

    it "accepts today" do
      expect(build(:entry, occurred_on: Date.current)).to be_valid
    end

    it "accepts a past date" do
      expect(build(:entry, occurred_on: 5.years.ago.to_date)).to be_valid
    end

    it "rejects a future date" do
      entry = build(:entry, occurred_on: Date.current.tomorrow)

      expect(entry).not_to be_valid
      expect(entry.errors[:occurred_on]).to include("cannot be in the future")
    end

    # The reason this validation resolves against users.time_zone rather than
    # Date.current: at 23:00 UTC it is already tomorrow in Auckland, and an
    # entry made there is legitimately "today" for its owner.
    context "when the owner's zone is ahead of the server's" do
      let(:owner) { create(:user, time_zone: "Auckland") }
      let(:portfolio) { create(:portfolio, user: owner) }

      it "accepts a date that is today for the owner but tomorrow in UTC" do
        travel_to Time.utc(2026, 8, 8, 23, 0) do
          entry = build(:entry, portfolio:, occurred_on: Date.new(2026, 8, 9))

          expect(entry).to be_valid
        end
      end

      it "still rejects a date that is in the future for the owner too" do
        travel_to Time.utc(2026, 8, 8, 23, 0) do
          entry = build(:entry, portfolio:, occurred_on: Date.new(2026, 8, 10))

          expect(entry).not_to be_valid
        end
      end
    end

    context "when the owner is on UTC" do
      it "rejects the same date an Auckland owner would be allowed" do
        portfolio = create(:portfolio, user: create(:user, time_zone: "UTC"))

        travel_to Time.utc(2026, 8, 8, 23, 0) do
          entry = build(:entry, portfolio:, occurred_on: Date.new(2026, 8, 9))

          expect(entry).not_to be_valid
        end
      end
    end
  end

  describe "nested line items" do
    it "accepts them" do
      expect(described_class.nested_attributes_options).to have_key(:entry_line_items)
    end
  end

  describe "#total_amount_by_currency" do
    it "keeps a EUR line and a USD line on the same entry apart, never blended into one number" do
      entry = create(:entry)
      eur_asset = create(:asset, currency: "EUR")
      usd_asset = create(:asset, currency: "USD")
      create(:entry_line_item, entry:, asset: eur_asset, quantity: 1, price_per_unit: 100, amount: -100)
      create(:entry_line_item, entry:, asset: usd_asset, action: :fee, amount: -5)

      expect(entry.total_amount_by_currency).to eq("EUR" => -100, "USD" => -5)
    end
  end
end
