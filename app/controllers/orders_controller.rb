class OrdersController < ApplicationController
  before_action :authenticate_customer!, only: :index

  def index
    @orders = current_customer.orders
      .includes(:order_items)
      .order(created_at: :desc)
      .page(params[:page])
      .per(10)
  end

  def show
    permitted_order_ids = Array(session[:completed_order_ids]).map(&:to_i)
    @order = Order.includes(:customer, :order_items).find(params[:id])

    customer_owns_order = customer_signed_in? && @order.customer_id == current_customer.id
    return if customer_owns_order || permitted_order_ids.include?(@order.id)

    redirect_to root_path, alert: "That invoice is not available in this session."
  end
end
