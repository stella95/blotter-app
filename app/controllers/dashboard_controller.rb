class DashboardController < ApplicationController
  def index
    @portfolios = current_user.portfolios.active
  end
end
