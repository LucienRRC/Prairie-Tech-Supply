class OrderPaymentExpiration
  def self.call(stripe_session)
    Order.find_by(stripe_checkout_session_id: stripe_session.id)&.cancel_and_release_inventory!
  end
end
