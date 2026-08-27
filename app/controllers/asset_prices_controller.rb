class AssetPricesController < ApplicationController
  def create
    @asset = Asset.find(params[:asset_id])
    @price = @asset.asset_prices.new(price_params.merge(as_of: Time.current))

    if @price.save
      redirect_to assets_path, notice: t("assets.flash.price_set", symbol: @asset.symbol)
    else
      redirect_to assets_path, alert: @price.errors.full_messages.to_sentence
    end
  end

  private

  def price_params
    params.require(:asset_price).permit(:price)
  end
end
