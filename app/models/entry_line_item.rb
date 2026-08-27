class EntryLineItem < ApplicationRecord
  enum :action, { buy: "buy", sell: "sell", dividend: "dividend", interest: "interest", deposit: "deposit", withdrawal: "withdrawal", fee: "fee", transfer_in: "transfer_in", transfer_out: "transfer_out" }, validate: true

  UNIT_BEARING_ACTIONS = %w[buy sell transfer_in transfer_out].freeze

  belongs_to :entry, inverse_of: :entry_line_items
  belongs_to :asset

  has_many :category_entry_line_items, dependent: :destroy
  has_many :categories, through: :category_entry_line_items

  delegate :portfolio, :occurred_on, to: :entry, allow_nil: true

  validates :quantity, presence: true, numericality: true
  validates :amount, presence: true, numericality: true
  validates :price_per_unit,
            numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  validates :quantity, numericality: { greater_than: 0 }, if: :unit_bearing?
  validates :price_per_unit, presence: true, if: :buy_or_sell?

  validate :amount_matches_trade_value, if: :buy_or_sell?

  scope :unit_bearing, -> { where(action: UNIT_BEARING_ACTIONS) }
  scope :for_user, ->(user) { joins(entry: :portfolio).where(portfolios: { user_id: user.id }) }
  scope :in_portfolio, ->(portfolio_id) { joins(:entry).where(entries: { portfolio_id: }) }
  scope :with_action, ->(action) { where(action:) }
  scope :chronological, -> { joins(:entry).order("entries.occurred_on DESC, entry_line_items.id DESC") }

  def unit_bearing?
    UNIT_BEARING_ACTIONS.include?(action)
  end

  def buy_or_sell?
    buy? || sell?
  end

  def signed_quantity
    case action
    when "buy", "transfer_in"    then quantity
    when "sell", "transfer_out"  then -quantity
    else                              0
    end
  end

  def display_description
    notes.presence || entry.description.presence || "#{action.humanize} #{asset.symbol}"
  end

  private

  def amount_matches_trade_value
    return if quantity.blank? || price_per_unit.blank? || amount.blank?

    expected = quantity * price_per_unit
    expected = -expected if buy?
    return if amount == expected

    errors.add(:amount, :mismatch, expected: expected)
  end
end
