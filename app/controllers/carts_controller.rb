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
    quantity = [[requested_quantity(default: 1), 1].max, @product.stock_quantity].min
    cart[@product.id.to_s] = quantity
    session[:cart] = cart

    respond_to do |format|
      format.html { redirect_to cart_path, notice: "#{@product.name} quantity was updated." }
      format.json do
        totals = cart_totals(cart)
        render json: {
          quantity: cart.fetch(@product.id.to_s, 0),
          line_total: @product.selling_price * cart.fetch(@product.id.to_s, 0),
          subtotal: totals[:subtotal],
          item_count: totals[:item_count]
        }
      end
    end
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

  def cart_totals(cart)
    products = Product.available.where(id: cart.keys).index_by { |product| product.id.to_s }

    cart.each_with_object({ subtotal: 0.to_d, item_count: 0 }) do |(product_id, quantity), totals|
      product = products[product_id]
      next unless product

      valid_quantity = [[quantity.to_i, 1].max, product.stock_quantity].min
      totals[:subtotal] += product.selling_price * valid_quantity
      totals[:item_count] += valid_quantity
    end
  end
end
