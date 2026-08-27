class ApplicationController < ActionController::Base
  before_action :authenticate_user!
  before_action :configure_permitted_parameters, if: :devise_controller?

  allow_browser versions: :modern
  stale_when_importmap_changes

  protected

  def configure_permitted_parameters
    added_attrs = %i[first_name last_name email password password_confirmation current_password]
    devise_parameter_sanitizer.permit :sign_up, keys: added_attrs
    devise_parameter_sanitizer.permit :account_update, keys: added_attrs
  end
end
