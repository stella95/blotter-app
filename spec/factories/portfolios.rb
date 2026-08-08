FactoryBot.define do
  factory :portfolio do
    user
    sequence(:name) { |n| "Portfolio #{n}" }
    currency { "EUR" }
    archived_at { nil }
  end
end
