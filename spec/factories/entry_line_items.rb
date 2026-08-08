FactoryBot.define do
  factory :entry_line_item do
    entry
    asset
    action { :buy }
    quantity { 3 }
    price_per_unit { 250 }
    amount { -750 }
    notes { nil }

    trait :sell do
      action { :sell }
      quantity { 2 }
      price_per_unit { 260 }
      amount { 520 }
    end

    # Cash-only actions carry no units and no per-unit price.
    trait :fee do
      action { :fee }
      quantity { 0 }
      price_per_unit { nil }
      amount { -2 }
    end

    trait :deposit do
      action { :deposit }
      quantity { 0 }
      price_per_unit { nil }
      amount { 500 }
    end

    trait :dividend do
      action { :dividend }
      quantity { 0 }
      price_per_unit { nil }
      amount { 12.40 }
    end

    trait :transfer_in do
      action { :transfer_in }
      quantity { 5 }
      price_per_unit { nil }
      amount { 0 }
    end

    trait :transfer_out do
      action { :transfer_out }
      quantity { 5 }
      price_per_unit { nil }
      amount { 0 }
    end
  end
end
