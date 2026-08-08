class PortfolioSnapshot < ApplicationRecord
  belongs_to :portfolio

  normalizes :currency, with: ->(value) { value.to_s.strip.upcase }

  validates :captured_on, presence: true,
                          uniqueness: { scope: [ :portfolio_id, :currency ] }
  validates :currency, presence: true, format: { with: /\A[A-Z]{3}\z/ }
  validates :total_market_value, :total_cost_basis, :net_cash_flow_to_date,
            presence: true, numericality: true
  validates :unpriced_assets_count,
            numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  scope :in_currency, ->(currency) { where(currency: currency.to_s.upcase) }
  scope :chronological, -> { order(:captured_on) }
  scope :between, ->(from, to) { where(captured_on: from..to) }

  def complete?
    unpriced_assets_count.zero?
  end
end
