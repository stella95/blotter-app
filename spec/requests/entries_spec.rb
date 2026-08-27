require "rails_helper"

RSpec.describe "Entries" do
  let(:user) { create(:user) }
  let(:portfolio) { create(:portfolio, user:) }
  let(:asset) { create(:asset) }

  before { sign_in user }

  describe "GET /entries" do
    it "lists only the current user's line items" do
      mine = create(:entry_line_item, entry: create(:entry, portfolio:, description: "Mine"), asset:)
      other_portfolio = create(:portfolio, user: create(:user))
      create(:entry_line_item, entry: create(:entry, portfolio: other_portfolio, description: "Not mine"), asset:)

      get entries_path

      expect(response.body).to include(mine.entry.description)
      expect(response.body).not_to include("Not mine")
    end

    it "filters to a single portfolio when portfolio_id is given" do
      brokerage = create(:portfolio, user:, name: "Brokerage")
      crypto = create(:portfolio, user:, name: "Crypto")
      create(:entry_line_item, entry: create(:entry, portfolio: brokerage, description: "Brokerage buy"), asset:)
      create(:entry_line_item, entry: create(:entry, portfolio: crypto, description: "Crypto buy"), asset:)

      get entries_path(portfolio_id: crypto.id)

      expect(response.body).to include("Crypto buy")
      expect(response.body).not_to include("Brokerage buy")
    end

    it "filters to a single asset when asset_id is given" do
      vwce = create(:asset, symbol: "VWCE")
      btc = create(:asset, symbol: "BTC")
      create(:entry_line_item, entry: create(:entry, portfolio:, description: "VWCE buy"), asset: vwce)
      create(:entry_line_item, entry: create(:entry, portfolio:, description: "BTC buy"), asset: btc)

      get entries_path(asset_id: btc.id)

      expect(response.body).to include("BTC buy")
      expect(response.body).not_to include("VWCE buy")
    end

    it "filters to a single action when action is given" do
      create(:entry_line_item, entry: create(:entry, portfolio:, description: "A buy"), asset:, action: :buy)
      create(:entry_line_item, :sell, entry: create(:entry, portfolio:, description: "A sell"), asset:)

      get entries_path(entry_action: "sell")

      expect(response.body).to include("A sell")
      expect(response.body).not_to include("A buy")
    end
  end

  describe "GET /entries/new" do
    it "shows the form when the user has a portfolio" do
      portfolio

      get new_entry_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(portfolio.name)
    end

    it "prompts to create a portfolio first when there is none" do
      get new_entry_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(I18n.t("entries.new.no_portfolios"))
    end
  end

  describe "POST /entries" do
    it "creates an entry with nested line items" do
      portfolio

      expect {
        post entries_path, params: {
          entry: {
            occurred_on: Date.current, description: "Monthly ETF purchase", portfolio_id: portfolio.id,
            entry_line_items_attributes: {
              "0" => { asset_id: asset.id, action: "buy", quantity: "3", price_per_unit: "250", amount: "-750" },
              "1" => { asset_id: asset.id, action: "fee", amount: "-2" }
            }
          }
        }
      }.to change(Entry, :count).by(1).and change(EntryLineItem, :count).by(2)

      expect(response).to redirect_to(entries_path)
    end

    it "re-renders the form when a line item is invalid" do
      portfolio

      expect {
        post entries_path, params: {
          entry: {
            occurred_on: Date.current, description: "Bad entry", portfolio_id: portfolio.id,
            entry_line_items_attributes: {
              "0" => { asset_id: asset.id, action: "buy", quantity: "3", price_per_unit: "250", amount: "-700" }
            }
          }
        }
      }.not_to change(Entry, :count)

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "will not assign an entry to another user's portfolio" do
      other_portfolio = create(:portfolio, user: create(:user))

      post entries_path, params: {
        entry: {
          occurred_on: Date.current, description: "Sneaky", portfolio_id: other_portfolio.id,
          entry_line_items_attributes: { "0" => { asset_id: asset.id, action: "deposit", amount: "10" } }
        }
      }

      expect(response).to have_http_status(:not_found)
    end
  end
end
