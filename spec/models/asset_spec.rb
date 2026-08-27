require 'rails_helper'

RSpec.describe Asset do
  describe "validations" do
    subject { build(:asset) }

    it { is_expected.to validate_presence_of(:symbol) }
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:symbol).case_insensitive }

    it "defines the asset types" do
      expect(described_class.asset_types.keys)
        .to contain_exactly("stock", "etf", "bond", "cash", "crypto", "mutual_fund")
    end

    it "rejects a currency that is not a three letter code" do
      expect(build(:asset, currency: "Euro")).not_to be_valid
    end
  end

  describe "normalization" do
    it "upcases and strips the symbol" do
      expect(create(:asset, symbol: "  vti ").symbol).to eq("VTI")
    end
  end

  describe "#price_on" do
    let(:asset) { create(:asset) }

    # The carry-forward rule. Prices are entered by hand, roughly weekly, but
    # the snapshot job runs daily, so most days have no price of their own and
    # must inherit the last one known.
    it "returns the most recent price on or before the given date" do
      create(:asset_price, asset:, price: 100, as_of: 10.days.ago)
      create(:asset_price, asset:, price: 130, as_of: 3.days.ago)

      expect(asset.price_on(5.days.ago.to_date).price).to eq(100)
    end

    it "includes a price recorded later the same day" do
      create(:asset_price, asset:, price: 175, as_of: Time.current.change(hour: 18))

      expect(asset.price_on(Date.current).price).to eq(175)
    end

    it "returns nil when no price predates the given date" do
      create(:asset_price, asset:, price: 100, as_of: 1.day.ago)

      expect(asset.price_on(30.days.ago.to_date)).to be_nil
    end

    # The cutoff must follow the app's configured Time.zone, not the server's
    # OS clock, or the same lookup would answer differently depending on what
    # machine it happens to run on.
    it "resolves the day cutoff against Time.zone rather than the system clock" do
      create(:asset_price, asset:, price: 999, as_of: Time.utc(2026, 8, 25, 23, 30))

      Time.use_zone("UTC") do
        expect(asset.price_on(Date.new(2026, 8, 25)).price).to eq(999)
      end

      Time.use_zone("Auckland") do
        expect(asset.price_on(Date.new(2026, 8, 25))).to be_nil
      end
    end
  end

  describe "deletion" do
    # Deleting a traded asset would orphan history. Retirement is the soft path.
    it "is blocked once the asset has been traded" do
      asset = create(:asset)
      create(:entry_line_item, asset:)

      expect(asset.destroy).to be false
      expect(asset.errors[:base]).to be_present
    end

    it "is allowed for an asset with no history" do
      expect(create(:asset).destroy).to be_truthy
    end
  end

  describe "#stale_price?" do
    it "is true with no price at all" do
      expect(create(:asset)).to be_stale_price
    end

    it "is true when the latest price is over a week old" do
      asset = create(:asset)
      create(:asset_price, asset:, as_of: 8.days.ago)

      expect(asset).to be_stale_price
    end

    it "is false when the latest price is recent" do
      asset = create(:asset)
      create(:asset_price, asset:, as_of: 1.day.ago)

      expect(asset).not_to be_stale_price
    end
  end

  describe ".tradeable" do
    it "excludes retired assets" do
      live = create(:asset)
      create(:asset, :retired)

      expect(described_class.tradeable).to contain_exactly(live)
    end
  end
end
