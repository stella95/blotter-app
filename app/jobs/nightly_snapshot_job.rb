class NightlySnapshotJob
  include Sidekiq::Job

  # Reads the ledger and records what it found, same as every other total
  # in this app; it never writes a ledger row itself. Safe to run more
  # than once for the same day, find_or_initialize_by plus the unique
  # index on (portfolio_id, currency, captured_on) makes a rerun update
  # today's row instead of duplicating it.
  def perform
    Portfolio.active.find_each { |portfolio| snapshot(portfolio) }
  end

  private

  def snapshot(portfolio)
    holdings = portfolio.current_holdings
    market_values = Portfolio.totals_by_currency(holdings)
    cost_basis = portfolio.cost_basis_by_currency
    cash_flow = portfolio.net_cash_flow_by_currency
    unpriced_counts = portfolio.unpriced_counts_by_currency
    captured_on = portfolio.user.today

    portfolio.currencies_held.each do |currency|
      snapshot = PortfolioSnapshot.find_or_initialize_by(portfolio:, currency:, captured_on:)
      snapshot.update!(
        total_market_value: market_values[currency] || 0,
        total_cost_basis: cost_basis[currency] || 0,
        net_cash_flow_to_date: cash_flow[currency] || 0,
        unpriced_assets_count: unpriced_counts[currency] || 0
      )
    end
  end
end
