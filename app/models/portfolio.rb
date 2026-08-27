class Portfolio < ApplicationRecord
  belongs_to :user

  has_many :entries, dependent: :restrict_with_error
  has_many :entry_line_items, through: :entries
  has_many :portfolio_snapshots, dependent: :destroy

  normalizes :currency, with: ->(value) { value.to_s.strip.upcase }

  validates :name, presence: true,
                   uniqueness: { scope: :user_id, case_sensitive: false }
  validates :currency, presence: true, format: { with: /\A[A-Z]{3}\z/ }

  scope :active, -> { where(archived_at: nil) }
  scope :archived, -> { where.not(archived_at: nil) }

  def archived?
    archived_at.present?
  end

  def archive!
    update!(archived_at: Time.current)
  end

  Holding = Struct.new(:asset, :quantity, :price, :value)

  def current_holdings
    entry_line_items.unit_bearing.includes(:asset).group_by(&:asset).filter_map do |asset, line_items|
      quantity = line_items.sum(&:signed_quantity)
      next if quantity.zero?

      price = asset.latest_price&.price
      Holding.new(asset, quantity, price, price && quantity * price)
    end
  end

  def currencies_held
    current_holdings.map { |holding| holding.asset.currency }.uniq.sort
  end
end
