require "rails_helper"

RSpec.describe "Assets" do
  let(:user) { create(:user) }

  before { sign_in user }

  describe "GET /assets" do
    it "lists tradeable assets, excluding retired ones" do
      live = create(:asset, symbol: "VWCE")
      create(:asset, :retired, symbol: "OLD")

      get assets_path

      expect(response.body).to include(live.symbol)
      expect(response.body).not_to include("OLD")
    end
  end

  describe "GET /assets/new" do
    it "renders as a plain page, no modal wrapper, when visited directly" do
      get new_asset_path

      expect(response.body).not_to include("modal-card")
      expect(response.body).to include(assets_path)
    end

    it "renders wrapped in the modal frame when opened from the New entry modal" do
      get new_asset_path, headers: { "Turbo-Frame" => "asset_modal" }

      expect(response.body).to include("modal-card")
      expect(response.body).to include('data-action="modal#close"')
    end
  end

  describe "POST /assets" do
    it "creates an asset and redirects to the index" do
      expect {
        post assets_path, params: { asset: { symbol: "VWCE", name: "FTSE All-World", asset_type: "etf", currency: "EUR" } }
      }.to change(Asset, :count).by(1)

      expect(response).to redirect_to(assets_path)
    end

    it "re-renders the form on invalid input" do
      expect {
        post assets_path, params: { asset: { symbol: "", name: "", asset_type: "etf", currency: "EUR" } }
      }.not_to change(Asset, :count)

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "closes the modal and appends the new option to every asset dropdown, when opened from the New entry modal" do
      post assets_path,
        params: { asset: { symbol: "VWCE", name: "FTSE All-World", asset_type: "etf", currency: "EUR" } },
        headers: { "Turbo-Frame" => "asset_modal" }

      expect(response.media_type).to eq(Mime[:turbo_stream])
      expect(response.body).to include('turbo-stream action="update" target="asset_modal"')
      expect(response.body).to include('turbo-stream action="append" targets=".asset-select"')
      expect(response.body).to include("VWCE")
    end

    it "still redirects normally when submitted as a plain page, even though Turbo requests turbo-stream" do
      post assets_path,
        params: { asset: { symbol: "VWCE", name: "FTSE All-World", asset_type: "etf", currency: "EUR" } },
        as: :turbo_stream

      expect(response).to redirect_to(assets_path)
    end
  end

  describe "POST /assets/:asset_id/prices" do
    it "sets a new price for the asset" do
      asset = create(:asset)

      expect {
        post asset_prices_path(asset), params: { asset_price: { price: "104.20" } }
      }.to change { asset.asset_prices.count }.by(1)

      expect(response).to redirect_to(assets_path)
      expect(asset.reload.latest_price.price).to eq(104.20)
    end
  end
end
