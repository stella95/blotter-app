class AssetsController < ApplicationController
  def index
    @assets = Asset.tradeable.order(:symbol)
  end

  def new
    @asset = Asset.new
  end

  def create
    @asset = Asset.new(asset_params)

    if @asset.save
      if turbo_frame_request?
        render formats: :turbo_stream
      else
        redirect_to assets_path, notice: t("assets.flash.created")
      end
    else
      render :new, status: :unprocessable_content
    end
  end

  private

  def asset_params
    params.require(:asset).permit(:symbol, :name, :asset_type, :currency)
  end
end
