class Category < ApplicationRecord
  belongs_to :user

  has_many :category_entry_line_items, dependent: :destroy
  has_many :entry_line_items, through: :category_entry_line_items

  normalizes :name, with: ->(value) { value.to_s.strip }

  validates :name, presence: true,
                   uniqueness: { scope: :user_id, case_sensitive: false }
  validates :color, format: { with: /\A#\h{6}\z/, allow_blank: true }
end
