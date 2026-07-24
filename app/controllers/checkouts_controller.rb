class CheckoutsController < ApplicationController
  before_action :load_provinces

  def new
    @customer = Customer.find_by(id: session[:customer_id]) || Customer.new
    load_cart_preview
  end

  def create
    processor = CheckoutProcessor.new(
      cart: session_cart,
      customer_attributes: customer_params.to_h.symbolize_keys
    )
    order = processor.call

    session[:customer_id] = processor.customer.id
    session[:cart] = {}
    completed_order_ids = Array(session[:completed_order_ids]).map(&:to_i)
    session[:completed_order_ids] = (completed_order_ids << order.id).uniq.last(10)

    redirect_to order_path(order), notice: "Your order was created successfully."
  rescue ActiveRecord::RecordInvalid => error
    @customer = error.record.is_a?(Customer) ? error.record : processor.customer
    @customer ||= Customer.new(customer_params)
    load_cart_preview
    flash.now[:alert] = error.record.errors.full_messages.to_sentence
    render :new, status: :unprocessable_entity
  rescue CheckoutProcessor::EmptyCartError
    redirect_to cart_path, alert: "Your cart is empty."
  rescue CheckoutProcessor::UnavailableProductError => error
    redirect_to cart_path, alert: error.message
  end

  private

  def load_provinces
    @provinces = Province.order(:name)
  end

  def load_cart_preview
    products = Product.available.where(id: session_cart.keys).index_by { |product| product.id.to_s }
    @checkout_items = session_cart.filter_map do |product_id, quantity|
      product = products[product_id]
      next unless product

      { product: product, quantity: quantity.to_i, line_total: product.selling_price * quantity.to_i }
    end
    @subtotal = @checkout_items.sum { |item| item[:line_total] }

    redirect_to cart_path, alert: "Your cart is empty." if @checkout_items.empty?
  end

  def customer_params
    params.require(:customer).permit(
      :first_name, :last_name, :email, :phone, :address, :city, :postal_code, :province_id
    )
  end
end
