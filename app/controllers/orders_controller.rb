class OrdersController < ApplicationController
  def show
    permitted_order_ids = Array(session[:completed_order_ids]).map(&:to_i)
    @order = Order.includes(:customer, :order_items).find(params[:id])

    return if permitted_order_ids.include?(@order.id)

    redirect_to root_path, alert: "That invoice is not available in this session."
  end
end
