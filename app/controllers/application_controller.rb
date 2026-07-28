class ApplicationController < ActionController::Base

  before_action :configure_permitted_parameters, if: :devise_controller?
  helper_method :cart_item_count

  protected

  def configure_permitted_parameters
    account_fields = [
      :username, :first_name, :last_name, :email, :phone,
      :address, :city, :postal_code, :province_id
    ]
    devise_parameter_sanitizer.permit(:sign_up, keys: account_fields)
    devise_parameter_sanitizer.permit(:account_update, keys: account_fields)
  end

  def after_sign_in_path_for(resource)
    return new_checkout_path if resource.is_a?(Customer) && session_cart.present?

    super
  end

  private

  def session_cart
    cart = session[:cart]
    return {} unless cart.is_a?(Hash)

    cart.transform_keys(&:to_s)
  end

  def cart_item_count
    session_cart.values.sum { |quantity| quantity.to_i }
  end
end
