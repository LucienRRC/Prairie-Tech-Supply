class OrderPaymentFulfillment
  class VerificationError < StandardError; end

  def self.call(stripe_session)
    order_id = stripe_session.metadata&.order_id || stripe_session.metadata&.[]("order_id")
    order = Order.find(order_id)
    verify_session!(order, stripe_session)

    order.with_lock do
      return order if order.paid? || order.shipped?
      raise VerificationError, "Only new orders can be marked as paid." unless order.new_order?

      order.update!(
        status: :paid,
        stripe_payment_intent_id: stripe_session.payment_intent,
        paid_at: Time.current
      )
    end
    order
  end

  def self.verify_session!(order, stripe_session)
    unless ActiveSupport::SecurityUtils.secure_compare(
      order.stripe_checkout_session_id.to_s,
      stripe_session.id.to_s
    )
      raise VerificationError, "Stripe Checkout Session does not match this order."
    end
    raise VerificationError, "Stripe has not confirmed this payment." unless stripe_session.payment_status == "paid"
    raise VerificationError, "Live-mode Stripe payments are disabled for this project." unless stripe_session.livemode == false
    raise VerificationError, "Payment currency must be CAD." unless stripe_session.currency.to_s.downcase == "cad"

    expected_amount = (order.total * 100).round.to_i
    raise VerificationError, "Paid amount does not match the order total." unless stripe_session.amount_total.to_i == expected_amount
  end

  private_class_method :verify_session!
end
