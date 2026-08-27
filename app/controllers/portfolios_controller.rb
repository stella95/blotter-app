class PortfoliosController < ApplicationController
  before_action :set_portfolio, only: %i[show edit update destroy archive]

  def index
    @portfolios = current_user.portfolios.active
  end

  def show
  end

  def new
    @portfolio = current_user.portfolios.new
  end

  def create
    @portfolio = current_user.portfolios.new(portfolio_params)

    if @portfolio.save
      redirect_to @portfolio, notice: t("portfolios.flash.created")
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
  end

  def update
    if @portfolio.update(portfolio_params)
      redirect_to @portfolio, notice: t("portfolios.flash.updated")
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    if @portfolio.destroy
      redirect_to portfolios_path, notice: t("portfolios.flash.deleted")
    else
      redirect_to @portfolio, alert: t("portfolios.flash.delete_blocked")
    end
  end

  def archive
    @portfolio.archive!
    redirect_to portfolios_path, notice: t("portfolios.flash.archived")
  end

  private

  def set_portfolio
    @portfolio = current_user.portfolios.find(params[:id])
  end

  def portfolio_params
    params.require(:portfolio).permit(:name)
  end
end
