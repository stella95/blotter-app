FactoryBot.define do
  factory :portfolio do
    user
    sequence(:name) { |n| "Portfolio #{n}" }
    archived_at { nil }
  end
end
