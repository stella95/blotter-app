namespace :demo do
  desc "Wipe and reseed the demo account's data. Safe to rerun any time, " \
       "only ever touches the one user given by DEMO_EMAIL (default demo@blotter.cc)."
  task reset: :environment do
    demo_email = ENV.fetch("DEMO_EMAIL", "demo@blotter.cc")
    user = User.find_by(email: demo_email)
    abort "No user found for #{demo_email}, create it first (see Phase 5)." unless user

    # Only ever deletes this one user's own data, never touches any other
    # account. Portfolio protects itself from destruction while it still has
    # entries (dependent: :restrict_with_error), so entries have to go first,
    # that cascades to line items and category links via Entry's own
    # dependent: :destroy. Portfolio's dependent: :destroy on snapshots
    # handles those once the portfolio itself goes.
    Entry.where(portfolio: user.portfolios).destroy_all
    user.portfolios.destroy_all

    today = user.today
    make_entry = lambda do |portfolio, days_ago, description|
      portfolio.entries.create!(occurred_on: today - days_ago, description:)
    end

    # Shared asset catalogue, find_or_create so reruns don't duplicate or
    # collide with the two cash assets db/seeds.rb already creates.
    eur_cash = Asset.find_or_create_by!(symbol: "EUR-CASH") { |a| a.name = "Euro cash"; a.currency = "EUR"; a.asset_type = :cash }
    usd_cash = Asset.find_or_create_by!(symbol: "USD-CASH") { |a| a.name = "US dollar cash"; a.currency = "USD"; a.asset_type = :cash }
    vwce     = Asset.find_or_create_by!(symbol: "VWCE")     { |a| a.name = "FTSE All-World UCITS ETF"; a.currency = "EUR"; a.asset_type = :etf }
    aapl     = Asset.find_or_create_by!(symbol: "AAPL")     { |a| a.name = "Apple Inc."; a.currency = "USD"; a.asset_type = :stock }
    btc      = Asset.find_or_create_by!(symbol: "BTC")      { |a| a.name = "Bitcoin"; a.currency = "USD"; a.asset_type = :crypto }

    { eur_cash => 1.0, usd_cash => 1.0, vwce => 108.40, aapl => 232.10, btc => 63_500.00 }.each do |asset, price|
      AssetPrice.create!(asset:, price:, as_of: Time.current)
    end

    # The three defaults already exist from sign-up (see User#seed_default_categories).
    categories = user.categories.index_by(&:name)
    categories["Speculative"] ||= user.categories.create!(name: "Speculative")

    brokerage = user.portfolios.create!(name: "Brokerage")
    crypto    = user.portfolios.create!(name: "Crypto")

    # Brokerage, EUR. Dates are always relative to today, so the demo never
    # looks stale no matter when this task runs.
    e = make_entry.call(brokerage, 45, "Salary transfer in")
    e.entry_line_items.create!(action: :deposit, asset: eur_cash, quantity: 0, amount: 2000.00, categories: [ categories["Income"] ])

    e = make_entry.call(brokerage, 43, "Monthly ETF purchase")
    e.entry_line_items.create!(action: :buy, asset: vwce, quantity: 12, price_per_unit: 104.20, amount: -1250.40, categories: [ categories["Core"] ])
    e.entry_line_items.create!(action: :fee, asset: eur_cash, quantity: 0, amount: -2.50, categories: [ categories["Fees"] ])

    e = make_entry.call(brokerage, 39, "VWCE dividend")
    e.entry_line_items.create!(action: :dividend, asset: vwce, quantity: 0, amount: 18.60, categories: [ categories["Income"] ])

    e = make_entry.call(brokerage, 36, "AAPL purchase")
    e.entry_line_items.create!(action: :buy, asset: aapl, quantity: 5, price_per_unit: 225.00, amount: -1125.00, categories: [ categories["Core"] ])

    e = make_entry.call(brokerage, 32, "Custody fee")
    e.entry_line_items.create!(action: :fee, asset: eur_cash, quantity: 0, amount: -3.00, categories: [ categories["Fees"] ])

    e = make_entry.call(brokerage, 25, "AAPL trim")
    e.entry_line_items.create!(action: :sell, asset: aapl, quantity: 2, price_per_unit: 230.00, amount: 460.00, categories: [ categories["Core"] ])

    e = make_entry.call(brokerage, 20, "Second ETF purchase")
    e.entry_line_items.create!(action: :buy, asset: vwce, quantity: 5, price_per_unit: 105.00, amount: -525.00, categories: [ categories["Core"] ])

    e = make_entry.call(brokerage, 10, "VWCE dividend")
    e.entry_line_items.create!(action: :dividend, asset: vwce, quantity: 0, amount: 22.10, categories: [ categories["Income"] ])

    # Crypto, USD.
    e = make_entry.call(crypto, 40, "Transfer in from exchange")
    e.entry_line_items.create!(action: :transfer_in, asset: btc, quantity: 0.02, amount: 0)

    e = make_entry.call(crypto, 34, "BTC purchase")
    e.entry_line_items.create!(action: :buy, asset: btc, quantity: 0.012, price_per_unit: 61_000, amount: -732.00, categories: [ categories["Speculative"] ])

    e = make_entry.call(crypto, 15, "Crypto custody fee")
    e.entry_line_items.create!(action: :fee, asset: usd_cash, quantity: 0, amount: -5.00, categories: [ categories["Fees"] ])

    e = make_entry.call(crypto, 5, "BTC purchase")
    e.entry_line_items.create!(action: :buy, asset: btc, quantity: 0.008, price_per_unit: 64_000, amount: -512.00, categories: [ categories["Speculative"] ])

    # Snapshot history for the dashboard's value-over-time chart: today's row
    # uses the real computation (same formulas NightlySnapshotJob uses), the
    # 30 days before it are a fabricated smooth trend leading up to that real
    # value, just so the chart has something to draw without waiting weeks.
    [ brokerage, crypto ].each do |portfolio|
      holdings = portfolio.current_holdings
      market_by_currency = Portfolio.totals_by_currency(holdings)
      cost_by_currency = portfolio.cost_basis_by_currency
      flow_by_currency = portfolio.net_cash_flow_by_currency
      unpriced_by_currency = portfolio.unpriced_counts_by_currency

      portfolio.currencies_held.each do |currency|
        final_market = market_by_currency[currency] || 0
        final_cost   = cost_by_currency[currency] || 0
        final_flow   = flow_by_currency[currency] || 0

        30.downto(1) do |days_ago|
          progress = (30 - days_ago) / 30.0
          noise = 1 + rand(-0.02..0.02)
          PortfolioSnapshot.find_or_initialize_by(portfolio:, currency:, captured_on: today - days_ago).update!(
            total_market_value: [ final_market * progress * noise, 0 ].max.round(2),
            total_cost_basis: [ final_cost * progress, 0 ].max.round(2),
            net_cash_flow_to_date: (final_flow * progress).round(2),
            unpriced_assets_count: 0
          )
        end

        PortfolioSnapshot.find_or_initialize_by(portfolio:, currency:, captured_on: today).update!(
          total_market_value: final_market,
          total_cost_basis: final_cost,
          net_cash_flow_to_date: final_flow,
          unpriced_assets_count: unpriced_by_currency[currency] || 0
        )
      end
    end

    puts "Demo reset for #{user.email}: #{user.portfolios.count} portfolios, " \
         "#{EntryLineItem.for_user(user).count} line items, " \
         "#{PortfolioSnapshot.joins(:portfolio).where(portfolios: { user_id: user.id }).count} snapshot rows."
  end
end
