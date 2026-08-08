class AssetPrice < ApplicationRecord
  belongs_to :asset

  validates :price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :as_of, presence: true, uniqueness: { scope: :asset_id }

  scope :on_or_before, ->(cutoff) { where(as_of: ..cutoff) }
  scope :most_recent_first, -> { order(as_of: :desc) }
end
