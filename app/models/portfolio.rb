class Portfolio < ApplicationRecord
  belongs_to :user

  has_many :entries, dependent: :restrict_with_error
  has_many :entry_line_items, through: :entries
  has_many :portfolio_snapshots, dependent: :destroy

  validates :name, presence: true,
                   uniqueness: { scope: :user_id, case_sensitive: false }

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

  # Average cost, not FIFO or LIFO: total spent on buys divided by total
  # quantity bought, times what's still held. Simpler to compute and to
  # audit than tracking individual lots, at the cost of not distinguishing
  # which specific shares were sold.
  def cost_basis_by_currency
    total_cost_by_asset = entry_line_items.where(action: "buy").includes(:asset)
                                           .group_by(&:asset)
                                           .transform_values { |lines| lines.sum(&:amount).abs }
    total_quantity_by_asset = entry_line_items.where(action: "buy")
                                               .group_by(&:asset_id)
                                               .transform_values { |lines| lines.sum(&:quantity) }

    current_holdings.group_by { |holding| holding.asset.currency }.transform_values do |holdings|
      holdings.sum do |holding|
        bought = total_quantity_by_asset[holding.asset.id]
        next 0 if bought.blank? || bought.zero?

        (total_cost_by_asset[holding.asset] / bought) * holding.quantity
      end
    end
  end

  def net_cash_flow_by_currency
    entry_line_items.where(action: %w[deposit withdrawal]).includes(:asset)
                     .group_by { |line_item| line_item.asset.currency }
                     .transform_values { |lines| lines.sum(&:amount) }
  end

  def unpriced_counts_by_currency
    current_holdings.group_by { |holding| holding.asset.currency }
                     .transform_values { |holdings| holdings.count { |h| h.price.nil? } }
  end

  def self.combined_holdings(portfolios)
    portfolios.flat_map(&:current_holdings)
              .group_by(&:asset)
              .map do |asset, holdings|
      quantity = holdings.sum(&:quantity)
      price = asset.latest_price&.price
      Holding.new(asset, quantity, price, price && quantity * price)
    end
  end

  def self.totals_by_currency(holdings)
    holdings.group_by { |holding| holding.asset.currency }
            .transform_values { |hs| hs.sum { |h| h.value || 0 } }
  end

  def self.names_by_currency(portfolios)
    portfolios.each_with_object(Hash.new { |h, k| h[k] = [] }) do |portfolio, names|
      portfolio.currencies_held.each { |currency| names[currency] << portfolio.name }
    end.transform_values { |names| names.join(" + ") }
  end

  # Percent of that currency's value held in each asset type. Blending two
  # currencies into one percentage breakdown would quietly assume an
  # exchange rate between them, so this is always scoped to a single
  # currency, same rule as every other total in the app.
  def self.allocation_by_type(holdings, currency)
    priced = holdings.select { |holding| holding.asset.currency == currency && holding.value }
    total = priced.sum(&:value)
    return {} if total.zero?

    priced.group_by { |holding| holding.asset.asset_type }
          .transform_values { |hs| (hs.sum(&:value).to_f / total * 100).round(1) }
          .sort_by { |_type, percent| -percent }
          .to_h
  end
end
