class Asset < ApplicationRecord
  enum :asset_type, { stock: "stock", etf: "etf", bond: "bond", cash: "cash", crypto: "crypto", mutual_fund: "mutual_fund" }, validate: true

  has_many :asset_prices, dependent: :destroy
  has_many :entry_line_items, dependent: :restrict_with_error

  normalizes :symbol, with: ->(value) { value.to_s.strip.upcase }
  normalizes :currency, with: ->(value) { value.to_s.strip.upcase }

  validates :symbol, presence: true, uniqueness: { case_sensitive: false }
  validates :name, presence: true
  validates :currency, presence: true, format: { with: /\A[A-Z]{3}\z/ }
  validates :isin, uniqueness: true, allow_nil: true
  validates :coupon_rate, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :face_value, numericality: { greater_than: 0 }, allow_nil: true

  scope :tradeable, -> { where(active: true) }

  # end_of_day resolves against Rails' Time.zone, not the server's own clock,
  # so the cutoff is consistent no matter what machine this runs on.
  def price_on(date)
    asset_prices.on_or_before(date.end_of_day).most_recent_first.first
  end

  def latest_price
    asset_prices.most_recent_first.first
  end
end
