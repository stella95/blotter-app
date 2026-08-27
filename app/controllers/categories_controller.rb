class CategoriesController < ApplicationController
  before_action :set_category, only: :destroy

  def index
    @categories = current_user.categories.order(:name)
  end

  def new
    @category = current_user.categories.new
  end

  def create
    @category = current_user.categories.new(category_params)

    if @category.save
      redirect_to categories_path, notice: t("categories.flash.created")
    else
      render :new, status: :unprocessable_content
    end
  end

  def destroy
    @category.destroy
    redirect_to categories_path, notice: t("categories.flash.deleted")
  end

  private

  def set_category
    @category = current_user.categories.find(params[:id])
  end

  def category_params
    params.require(:category).permit(:name, :color)
  end
end
