class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  helper_method :cart_item_count

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
