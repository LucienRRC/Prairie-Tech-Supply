class StripeWebhooksController < ApplicationController
  skip_forgery_protection

  def create
    event = Stripe::Webhook.construct_event(
      request.raw_post,
      request.headers["Stripe-Signature"],
      webhook_secret
    )

    case event.type
    when "checkout.session.completed", "checkout.session.async_payment_succeeded"
      OrderPaymentFulfillment.call(event.data.object)
    when "checkout.session.expired"
      OrderPaymentExpiration.call(event.data.object)
    end
    head :ok
  rescue JSON::ParserError, Stripe::SignatureVerificationError
    head :bad_request
  rescue OrderPaymentFulfillment::VerificationError, ActiveRecord::RecordNotFound => error
    Rails.logger.error("Rejected Stripe webhook: #{error.message}")
    head :unprocessable_entity
  rescue StripeCheckoutSession::ConfigurationError
    head :service_unavailable
  end

  private

  def webhook_secret
    secret = Rails.application.config.x.stripe.webhook_secret
    return secret if secret.present?

    raise StripeCheckoutSession::ConfigurationError, "STRIPE_WEBHOOK_SECRET is not configured."
  end
end
