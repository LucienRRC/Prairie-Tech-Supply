class CheckoutProcessor
  class EmptyCartError < StandardError; end
  class UnavailableProductError < StandardError; end

  attr_reader :customer

  def initialize(cart:, customer_attributes:)
    @cart = cart
    @customer_attributes = customer_attributes
  end

  def call
    raise EmptyCartError, "Your cart is empty." if @cart.blank?

    ActiveRecord::Base.transaction do
      products = Product.lock.where(id: @cart.keys).index_by { |product| product.id.to_s }
      validate_products!(products)

      @customer = Customer.find_or_initialize_by(
        email: @customer_attributes.fetch(:email).to_s.strip.downcase
      )
      @customer.assign_attributes(@customer_attributes)
      @customer.save!

      order = build_order(products)
      order.save!
      create_order_items!(order, products)
      reduce_inventory!(products)
      order
    end
  end

  private

  def validate_products!(products)
    @cart.each do |product_id, quantity|
      product = products[product_id.to_s]
      requested = quantity.to_i

      unless product&.active? && requested.positive? && product.stock_quantity >= requested
        raise UnavailableProductError, "One or more products are no longer available in the requested quantity."
      end
    end
  end

  def build_order(products)
    subtotal = @cart.sum do |product_id, quantity|
      products.fetch(product_id.to_s).selling_price * quantity.to_i
    end.round(2)
    province = @customer.province
    gst_amount = (subtotal * province.gst_rate).round(2)
    pst_amount = (subtotal * province.pst_rate).round(2)
    hst_amount = (subtotal * province.hst_rate).round(2)

    @customer.orders.build(
      user: nil,
      status: :pending,
      delivery_method: @customer.address.present? ? :shipping : :in_store_pickup,
      subtotal: subtotal,
      gst_amount: gst_amount,
      pst_amount: pst_amount,
      hst_amount: hst_amount,
      delivery_fee: 0,
      total: subtotal + gst_amount + pst_amount + hst_amount,
      recipient_name: "#{@customer.first_name} #{@customer.last_name}",
      phone: @customer.phone,
      address: @customer.address,
      city: @customer.city,
      postal_code: @customer.postal_code,
      province_name: province.name,
      gst_rate: province.gst_rate,
      pst_rate: province.pst_rate,
      hst_rate: province.hst_rate
    )
  end

  def create_order_items!(order, products)
    @cart.each do |product_id, quantity|
      product = products.fetch(product_id.to_s)
      unit_price = product.selling_price
      order.order_items.create!(
        product: product,
        product_name: product.name,
        sku: product.sku,
        quantity: quantity,
        unit_price: unit_price,
        line_total: unit_price * quantity.to_i
      )
    end
  end

  def reduce_inventory!(products)
    @cart.each do |product_id, quantity|
      product = products.fetch(product_id.to_s)
      product.update!(stock_quantity: product.stock_quantity - quantity.to_i)
    end
  end
end
