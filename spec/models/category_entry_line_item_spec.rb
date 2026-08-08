require 'rails_helper'

RSpec.describe CategoryEntryLineItem do
  let(:owner) { create(:user) }
  let(:portfolio) { create(:portfolio, user: owner) }
  let(:entry) { create(:entry, portfolio:) }
  let(:line_item) { create(:entry_line_item, entry:) }

  it "links a category to a line item owned by the same user" do
    join = build(:category_entry_line_item,
                 category: create(:category, user: owner),
                 entry_line_item: line_item)

    expect(join).to be_valid
  end

  # Categories are per user and the owner sits three joins away from the line
  # item, which is further than a database constraint can reach.
  it "refuses a category belonging to a different user" do
    join = build(:category_entry_line_item,
                 category: create(:category, user: create(:user)),
                 entry_line_item: line_item)

    expect(join).not_to be_valid
    expect(join.errors[:category]).to include("belongs to a different user")
  end

  it "refuses to tag the same line item twice with one category" do
    category = create(:category, user: owner)
    create(:category_entry_line_item, category:, entry_line_item: line_item)

    duplicate = build(:category_entry_line_item, category:, entry_line_item: line_item)

    expect(duplicate).not_to be_valid
  end

  it "allows several distinct categories on one line item" do
    create(:category_entry_line_item, category: create(:category, user: owner), entry_line_item: line_item)
    create(:category_entry_line_item, category: create(:category, user: owner), entry_line_item: line_item)

    expect(line_item.reload.categories.count).to eq(2)
  end
end
