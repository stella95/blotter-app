FactoryBot.define do
  factory :asset do
    sequence(:symbol) { |n| "SYM#{n}" }
    name { "Vanguard Total Stock Market ETF" }
    asset_type { :etf }
    currency { "USD" }
    active { true }
    isin { nil }

    trait :bond do
      asset_type { :bond }
      name { "German Federal Bond 2030" }
      currency { "EUR" }
      maturity_date { Date.new(2030, 1, 15) }
      coupon_rate { 2.5 }
      face_value { 1000 }
    end

    trait :crypto do
      asset_type { :crypto }
      name { "Bitcoin" }
      currency { "EUR" }
    end

    trait :cash do
      asset_type { :cash }
      name { "Euro cash" }
      currency { "EUR" }
    end

    trait :retired do
      active { false }
    end
  end
end
