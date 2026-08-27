class EntriesController < ApplicationController
  def index
    @portfolios = current_user.portfolios.active
    @assets = Asset.tradeable.order(:symbol)

    @line_items = EntryLineItem.for_user(current_user).includes(:asset, :categories, entry: :portfolio)
    @line_items = @line_items.in_portfolio(params[:portfolio_id]) if params[:portfolio_id].present?
    @line_items = @line_items.where(asset_id: params[:asset_id]) if params[:asset_id].present?
    @line_items = @line_items.with_action(params[:entry_action]) if params[:entry_action].present?
    @line_items = @line_items.chronological
  end

  def new
    @portfolios = current_user.portfolios.active
    @entry = @portfolios.first&.entries&.new
    2.times { @entry.entry_line_items.build } if @entry
  end

  def create
    @portfolios = current_user.portfolios.active
    portfolio = @portfolios.find(params.dig(:entry, :portfolio_id))
    @entry = portfolio.entries.new(entry_params)

    if @entry.save
      redirect_to entries_path, notice: t("entries.flash.created")
    else
      render :new, status: :unprocessable_content
    end
  end

  private

  def entry_params
    params.require(:entry).permit(
      :occurred_on, :description,
      entry_line_items_attributes: [ :id, :asset_id, :action, :quantity, :price_per_unit, :amount, :notes, :_destroy, { category_ids: [] } ]
    )
  end
end
