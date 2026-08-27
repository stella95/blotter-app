class Entry < ApplicationRecord
  belongs_to :portfolio
  has_many :entry_line_items, dependent: :destroy, inverse_of: :entry
  has_many :categories, -> { distinct }, through: :entry_line_items

  accepts_nested_attributes_for :entry_line_items, allow_destroy: true, reject_if: :all_blank

  validates :occurred_on, presence: true
  validate :occurred_on_cannot_be_in_the_future

  scope :chronological, -> { order(occurred_on: :desc, id: :desc) }
  scope :occurring_between, ->(from, to) { where(occurred_on: from..to) }

  def total_amount_by_currency
    entry_line_items.includes(:asset).group_by { |li| li.asset.currency }.transform_values { |lis| lis.sum(&:amount) }
  end

  private

  def occurred_on_cannot_be_in_the_future
    return if occurred_on.blank?
    return unless occurred_on > today_for_owner

    errors.add(:occurred_on, :future)
  end

  def today_for_owner
    zone_name = portfolio&.user&.time_zone.presence || Time.zone.name
    (Time.find_zone(zone_name) || Time.zone).today
  end
end
