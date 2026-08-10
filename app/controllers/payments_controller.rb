class PaymentsController < ApplicationController
  before_action :load_accessible_order

  def success
    unless @order.stripe_checkout_session_id.present? && params[:session_id].present? &&
        ActiveSupport::SecurityUtils.secure_compare(
      @order.stripe_checkout_session_id.to_s,
      params[:session_id].to_s
    )
      return redirect_to order_path(@order), alert: "Payment confirmation could not be verified."
    end

    stripe_session = StripeCheckoutSession.retrieve(params[:session_id])
    OrderPaymentFulfillment.call(stripe_session)
    redirect_to order_path(@order), notice: "Payment confirmed. Your order is now paid."
  rescue StripeCheckoutSession::ConfigurationError, Stripe::StripeError, OrderPaymentFulfillment::VerificationError
    redirect_to order_path(@order), alert: "Payment is still being confirmed. Please refresh your order shortly."
  end

  def cancel
    redirect_to order_path(@order), alert: "Payment was cancelled. This order remains unpaid."
  end

  private

  def load_accessible_order
    @order = Order.find(params[:order_id])
    permitted_order_ids = Array(session[:completed_order_ids]).map(&:to_i)
    customer_owns_order = customer_signed_in? && @order.customer_id == current_customer.id
    return if customer_owns_order || permitted_order_ids.include?(@order.id)

    redirect_to root_path, alert: "That order is not available in this session."
  end
end
