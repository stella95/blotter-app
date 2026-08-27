class CategoryEntryLineItem < ApplicationRecord
  belongs_to :category
  belongs_to :entry_line_item

  validates :category_id, uniqueness: { scope: :entry_line_item_id }

  validate :category_and_line_item_share_an_owner

  private

  def category_and_line_item_share_an_owner
    return if category.blank? || entry_line_item.blank?

    line_item_owner_id = entry_line_item.entry&.portfolio&.user_id
    return if line_item_owner_id.blank? || category.user_id == line_item_owner_id

    errors.add(:category, :different_user)
  end
end
