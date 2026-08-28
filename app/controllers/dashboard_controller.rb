class DashboardController < ApplicationController
  def index
    @portfolios = current_user.portfolios.active
    @holdings = Portfolio.combined_holdings(@portfolios)
    @totals_by_currency = Portfolio.totals_by_currency(@holdings)
    @portfolio_names_by_currency = Portfolio.names_by_currency(@portfolios)
    @unpriced_count = @holdings.count { |h| h.price.nil? }
    @recent_line_items = EntryLineItem.for_user(current_user)
                                       .includes(:asset, :categories, entry: :portfolio)
                                       .chronological
                                       .first(5)
    @value_over_time_by_currency = PortfolioSnapshot.where(portfolio: @portfolios)
                                                      .distinct.pluck(:currency).index_with do |currency|
      PortfolioSnapshot.where(portfolio: @portfolios, currency:)
                        .group_by_day(:captured_on)
                        .sum(:total_market_value)
    end
  end
end
