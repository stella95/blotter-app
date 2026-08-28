require "rails_helper"

RSpec.describe "Dashboard" do
  it "redirects to sign in when logged out" do
    get root_path

    expect(response).to redirect_to(new_user_session_path)
  end

  it "is reachable once signed in" do
    sign_in create(:user)

    get root_path

    expect(response).to have_http_status(:ok)
  end

  it "shows current holdings valued at the latest price" do
    user = create(:user)
    sign_in user
    portfolio = create(:portfolio, user:)
    asset = create(:asset, symbol: "VWCE")
    create(:asset_price, asset:, price: 104.20, as_of: 1.day.ago)
    create(:entry_line_item, entry: create(:entry, portfolio:), asset:, quantity: 10, price_per_unit: 100, amount: -1000)

    get root_path

    expect(response.body).to include("VWCE")
    expect(response.body).to include("$1,042.00")
  end

  it "merges the same asset held across two portfolios into one holding" do
    user = create(:user)
    sign_in user
    asset = create(:asset, symbol: "VWCE")
    create(:asset_price, asset:, price: 100, as_of: 1.day.ago)
    retirement = create(:portfolio, user:, name: "Retirement")
    brokerage = create(:portfolio, user:, name: "Brokerage")
    create(:entry_line_item, entry: create(:entry, portfolio: retirement), asset:, quantity: 4, price_per_unit: 90, amount: -360)
    create(:entry_line_item, entry: create(:entry, portfolio: brokerage), asset:, quantity: 6, price_per_unit: 90, amount: -540)

    get root_path

    expect(response.body.scan("VWCE").count).to eq(1)
    expect(response.body).to include("$1,000.00")
  end

  it "totals value per currency across portfolios, not per portfolio" do
    user = create(:user)
    sign_in user
    eur_asset = create(:asset, symbol: "VWCE", currency: "EUR")
    usd_asset = create(:asset, symbol: "BTC", currency: "USD")
    create(:asset_price, asset: eur_asset, price: 100, as_of: 1.day.ago)
    create(:asset_price, asset: usd_asset, price: 50_000, as_of: 1.day.ago)
    retirement = create(:portfolio, user:, name: "Retirement")
    brokerage = create(:portfolio, user:, name: "Brokerage")
    crypto = create(:portfolio, user:, name: "Crypto")
    create(:entry_line_item, entry: create(:entry, portfolio: retirement), asset: eur_asset, quantity: 2, price_per_unit: 90, amount: -180)
    create(:entry_line_item, entry: create(:entry, portfolio: brokerage), asset: eur_asset, quantity: 3, price_per_unit: 90, amount: -270)
    create(:entry_line_item, entry: create(:entry, portfolio: crypto), asset: usd_asset, quantity: 0.01, price_per_unit: 45_000, amount: -450)

    get root_path

    expect(response.body.scan("500.00").count).to be >= 2
  end

  it "puts a USD holding in a EUR-named portfolio into the USD total, not the EUR one" do
    user = create(:user)
    sign_in user
    brokerage = create(:portfolio, user:, name: "Brokerage")
    apple = create(:asset, symbol: "AAPL", currency: "USD")
    create(:asset_price, asset: apple, price: 200, as_of: 1.day.ago)
    create(:entry_line_item, entry: create(:entry, portfolio: brokerage), asset: apple, quantity: 5, price_per_unit: 180, amount: -900)

    get root_path

    expect(response.body).to include("Brokerage")
    expect(response.body).to include("$1,000.00")
  end

  it "shows the pending message when there is no snapshot history yet" do
    user = create(:user)
    sign_in user
    create(:portfolio, user:)

    get root_path

    expect(response.body).to include(I18n.t("dashboard.index.chart_pending"))
  end

  it "charts value over time once the nightly job has recorded history" do
    user = create(:user)
    sign_in user
    portfolio = create(:portfolio, user:)
    create(:portfolio_snapshot, portfolio:, currency: "EUR", captured_on: 2.days.ago)
    create(:portfolio_snapshot, portfolio:, currency: "EUR", captured_on: 1.day.ago)

    get root_path

    expect(response.body).to include(I18n.t("dashboard.index.value_over_time"))
    expect(response.body).not_to include(I18n.t("dashboard.index.chart_pending"))
  end

  it "warns when some held assets have no price yet" do
    user = create(:user)
    sign_in user
    portfolio = create(:portfolio, user:)
    unpriced = create(:asset, symbol: "GOVT")
    create(:entry_line_item, entry: create(:entry, portfolio:), asset: unpriced, quantity: 1, price_per_unit: 20, amount: -20)

    get root_path

    expect(response.body).to include(I18n.t("dashboard.index.unpriced_warning", count: 1))
  end
end
