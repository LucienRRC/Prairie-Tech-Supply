class CartsController < ApplicationController
  before_action :load_available_product, only: [:add, :update, :destroy]

  def show
    cart = session_cart
    products = Product.available
      .includes(:category, image_attachment: :blob)
      .where(id: cart.keys)
      .index_by { |product| product.id.to_s }

    cleaned_cart = {}
    @cart_items = cart.filter_map do |product_id, stored_quantity|
      product = products[product_id]
      next unless product

      quantity = [[stored_quantity.to_i, 1].max, product.stock_quantity].min
      cleaned_cart[product_id] = quantity
      { product: product, quantity: quantity, line_total: product.selling_price * quantity }
    end

    session[:cart] = cleaned_cart
    @subtotal = @cart_items.sum { |item| item[:line_total] }
  end

  def add
    cart = session_cart
    quantity = [requested_quantity(default: 1), 1].max
    existing_quantity = cart.fetch(@product.id.to_s, 0).to_i
    cart[@product.id.to_s] = [existing_quantity + quantity, @product.stock_quantity].min
    session[:cart] = cart

    redirect_to cart_path, notice: "#{@product.name} was added to your cart."
  end

  def update
    cart = session_cart
    quantity = requested_quantity(default: 1)

    if quantity <= 0
      cart.delete(@product.id.to_s)
      notice = "#{@product.name} was removed from your cart."
    else
      cart[@product.id.to_s] = [quantity, @product.stock_quantity].min
      notice = "#{@product.name} quantity was updated."
    end

    session[:cart] = cart
    redirect_to cart_path, notice: notice
  end

  def destroy
    cart = session_cart
    cart.delete(@product.id.to_s)
    session[:cart] = cart

    redirect_to cart_path, notice: "#{@product.name} was removed from your cart."
  end

  private

  def load_available_product
    @product = Product.available.find_by(id: params[:product_id])
    return if @product

    redirect_to products_path, alert: "That product is not currently available."
  end

  def requested_quantity(default:)
    Integer(params.fetch(:quantity, default))
  rescue ArgumentError, TypeError
    default
  end
end
