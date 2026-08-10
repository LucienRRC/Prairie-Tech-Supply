class StripeCheckoutSession
  class ConfigurationError < StandardError; end

  class << self
    def create(order:, success_url:, cancel_url:)
      ensure_secret_key!
      Stripe::Checkout::Session.create(
        {
          mode: "payment",
          payment_method_types: ["card"],
          customer_email: order.customer.email,
          client_reference_id: order.id.to_s,
          metadata: { order_id: order.id.to_s },
          payment_intent_data: { metadata: { order_id: order.id.to_s } },
          line_items: line_items_for(order),
          success_url: success_url,
          cancel_url: cancel_url
        },
        { api_key: secret_key, idempotency_key: "prairie-tech-order-#{order.id}" }
      )
    end

    def retrieve(session_id)
      ensure_secret_key!
      Stripe::Checkout::Session.retrieve(session_id, { api_key: secret_key })
    end

    private

    def line_items_for(order)
      items = order.order_items.map do |item|
        {
          quantity: item.quantity,
          price_data: {
            currency: "cad",
            unit_amount: cents(item.unit_price),
            product_data: { name: item.product_name, metadata: { sku: item.sku } }
          }
        }
      end
      items.concat(tax_line_items(order))
      items << amount_line_item("Delivery", order.delivery_fee) if order.delivery_fee.positive?
      items
    end

    def tax_line_items(order)
      { "GST" => order.gst_amount, "PST / QST" => order.pst_amount, "HST" => order.hst_amount }
        .filter_map { |name, amount| amount_line_item(name, amount) if amount.positive? }
    end

    def amount_line_item(name, amount)
      {
        quantity: 1,
        price_data: {
          currency: "cad",
          unit_amount: cents(amount),
          product_data: { name: name }
        }
      }
    end

    def cents(amount)
      (amount * 100).round.to_i
    end

    def secret_key
      Rails.application.config.x.stripe.secret_key
    end

    def ensure_secret_key!
      raise ConfigurationError, "STRIPE_SECRET_KEY is not configured." if secret_key.blank?
    end
  end
end
