FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "investor#{n}@example.com" }
    password { "correct horse battery staple" }
    time_zone { "UTC" }
  end
end
