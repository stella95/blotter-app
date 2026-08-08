FactoryBot.define do
  factory :category do
    user
    sequence(:name) { |n| "Category #{n}" }
    color { "#3366CC" }
  end
end
