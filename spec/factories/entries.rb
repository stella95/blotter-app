FactoryBot.define do
  factory :entry do
    portfolio
    occurred_on { Date.current }
    description { "Monthly contribution" }
    external_ref { nil }
  end
end
