FactoryBot.define do
  factory :portfolio_snapshot do
    portfolio
    captured_on { Date.current }
    currency { "EUR" }
    total_market_value { 48_213.77 }
    total_cost_basis { 41_000.00 }
    net_cash_flow_to_date { 40_000.00 }
    unpriced_assets_count { 0 }

    trait :incomplete do
      unpriced_assets_count { 3 }
    end
  end
end
