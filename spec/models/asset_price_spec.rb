require 'rails_helper'

RSpec.describe AssetPrice do
  it { is_expected.to belong_to(:asset) }

  describe "validations" do
    it { is_expected.to validate_presence_of(:price) }
    it { is_expected.to validate_presence_of(:as_of) }

    it "rejects a negative price" do
      expect(build(:asset_price, price: -1)).not_to be_valid
    end

    it "refuses two prices for one asset at the same instant" do
      asset = create(:asset)
      moment = Time.current.change(usec: 0)
      create(:asset_price, asset:, as_of: moment)

      expect(build(:asset_price, asset:, as_of: moment)).not_to be_valid
    end

    it "allows two assets to be priced at the same instant" do
      moment = Time.current.change(usec: 0)
      create(:asset_price, as_of: moment)

      expect(build(:asset_price, as_of: moment)).to be_valid
    end
  end

  describe "scopes" do
    it "orders most recent first" do
      asset = create(:asset)
      old = create(:asset_price, asset:, as_of: 5.days.ago)
      recent = create(:asset_price, asset:, as_of: 1.day.ago)

      expect(asset.asset_prices.most_recent_first).to eq([ recent, old ])
    end
  end
end
