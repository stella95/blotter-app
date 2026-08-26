FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "investor#{n}@example.com" }
    password { "Correct-Horse-Battery-9" }
    time_zone { "UTC" }
    confirmed_at { Time.current }

    trait :unconfirmed do
      confirmed_at { nil }
    end
  end
end
