FactoryBot.define do
  factory :category_entry_line_item do
    entry_line_item
    # Default to a category owned by the same user as the line item, since a
    # mismatch is rejected by validation.
    category do
      association :category, user: entry_line_item.entry.portfolio.user
    end
  end
end
