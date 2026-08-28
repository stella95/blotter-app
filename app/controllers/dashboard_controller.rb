class DashboardController < ApplicationController
  def index
    @all_portfolios = current_user.portfolios.active
    @portfolios = params[:portfolio_id].present? ? @all_portfolios.where(id: params[:portfolio_id]) : @all_portfolios
    @holdings = Portfolio.combined_holdings(@portfolios)
    @totals_by_currency = Portfolio.totals_by_currency(@holdings)
    @portfolio_names_by_currency = Portfolio.names_by_currency(@portfolios)
    @unpriced_count = @holdings.count { |h| h.price.nil? }

    @recent_line_items = EntryLineItem.for_user(current_user)
                                       .includes(:asset, :categories, entry: :portfolio)
    @recent_line_items = @recent_line_items.in_portfolio(params[:portfolio_id]) if params[:portfolio_id].present?
    @recent_line_items = @recent_line_items.chronological.first(5)

    @value_over_time_by_currency = PortfolioSnapshot.where(portfolio: @portfolios)
                                                      .distinct.pluck(:currency).index_with do |currency|
      PortfolioSnapshot.where(portfolio: @portfolios, currency:)
                        .group_by_day(:captured_on)
                        .sum(:total_market_value)
    end
    @allocation_by_currency = @totals_by_currency.keys.index_with do |currency|
      Portfolio.allocation_by_type(@holdings, currency)
    end
  end
end
