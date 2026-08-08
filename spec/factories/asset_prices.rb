FactoryBot.define do
  factory :asset_price do
    asset
    price { 250.123456 }
    as_of { Time.current.beginning_of_day }
  end
end
