ActiveAdmin.register Order do
  menu priority: 20, label: "Order History"
  actions :index, :show
  config.sort_order = "created_at_desc"
  config.filters = false

  scope :all, default: true
  scope("New") { |orders| orders.where(status: "new") }
  scope("Paid") { |orders| orders.where(status: "paid") }
  scope("Shipped") { |orders| orders.where(status: "shipped") }

  member_action :mark_shipped, method: :patch do
    resource.mark_shipped!
    redirect_to admin_order_path(resource), notice: "Order was marked as shipped."
  rescue ActiveRecord::RecordInvalid => error
    redirect_to admin_order_path(resource), alert: error.record.errors.full_messages.to_sentence
  end

  member_action :sync_payment_status, method: :patch do
    unless resource.new_order?
      return redirect_to admin_order_path(resource),
        alert: "Only new orders need Stripe payment confirmation."
    end

    if resource.stripe_checkout_session_id.blank?
      return redirect_to admin_order_path(resource),
        alert: "This order does not have a Stripe Checkout Session."
    end

    stripe_session = StripeCheckoutSession.retrieve(resource.stripe_checkout_session_id)
    OrderPaymentFulfillment.call(stripe_session)
    redirect_to admin_order_path(resource), notice: "Stripe confirmed the payment. Order status is now Paid."
  rescue StripeCheckoutSession::ConfigurationError, Stripe::StripeError,
      OrderPaymentFulfillment::VerificationError => error
    redirect_to admin_order_path(resource), alert: "Stripe payment was not confirmed: #{error.message}"
  end

  action_item :mark_shipped, only: :show, if: proc { resource.paid? } do
    link_to "Mark as shipped",
      mark_shipped_admin_order_path(resource),
      data: { turbo_method: :patch, turbo_confirm: "Confirm that this order has shipped?" }
  end

  includes :customer, :order_items

  index title: "Customer Order History", download_links: false do
    id_column
    column "Customer" do |order|
      div do
        strong order.recipient_name
        br
        span order.customer.email
        br
        span order.province_name
      end
    end
    column "Products ordered" do |order|
      ul class: "admin-order-products" do
        order.order_items.each do |item|
          li do
            span "#{item.quantity} x #{item.product_name}"
            strong number_to_currency(item.line_total)
          end
        end
      end
    end
    column "Taxes" do |order|
      div class: "admin-order-taxes" do
        span "GST: #{number_to_currency(order.gst_amount)}"
        span "Provincial: #{number_to_currency(order.pst_amount)}"
        span "HST: #{number_to_currency(order.hst_amount)}"
      end
    end
    column("Grand total") { |order| strong number_to_currency(order.total) }
    column :status do |order|
      status_tag order.status_label
    end
    column("Ordered") { |order| order.created_at.in_time_zone.to_fs(:short) }
    actions defaults: false do |order|
      item "Invoice details", admin_order_path(order), class: "member_link"
      if order.paid?
        item "Mark shipped",
          mark_shipped_admin_order_path(order),
          class: "member_link",
          data: { turbo_method: :patch, turbo_confirm: "Confirm shipment?" }
      end
    end
  end

  show title: proc { |order| "Order ##{order.id.to_s.rjust(6, '0')}" } do
    panel "Order Status Management" do
      div class: "admin-order-status-flow" do
        div do
          span "Current status: "
          status_tag order.status_label
        end

        if order.new_order?
          para "This order remains unpaid until Stripe confirms the card payment."
          if order.stripe_checkout_session_id.present?
            text_node link_to(
              "Check Stripe payment",
              sync_payment_status_admin_order_path(order),
              class: "button",
              data: {
                turbo_method: :patch,
                turbo_confirm: "Check this order's current payment status with Stripe?"
              }
            )
          else
            para "No Stripe Checkout Session is associated with this order."
          end
        elsif order.paid?
          para "Stripe has confirmed payment. Mark the order as shipped after it leaves the store."
          text_node link_to(
            "Mark as shipped",
            mark_shipped_admin_order_path(order),
            class: "button",
            data: {
              turbo_method: :patch,
              turbo_confirm: "Confirm that this order has shipped?"
            }
          )
        elsif order.shipped?
          para "This order was marked as shipped#{" on #{order.shipped_at.in_time_zone.to_fs(:long)}" if order.shipped_at}."
        else
          para "This order is cancelled and cannot move to another status."
        end
      end
    end

    attributes_table do
      row :customer do |order|
        "#{order.recipient_name} - #{order.customer.email}"
      end
      row :province_name
      row("Status") { |order| status_tag order.status_label }
      row :stripe_checkout_session_id
      row :stripe_payment_intent_id
      row :paid_at
      row :shipped_at
      row :delivery_method
      row(:subtotal) { |order| number_to_currency(order.subtotal) }
      row(:gst_amount) { |order| number_to_currency(order.gst_amount) }
      row(:pst_amount) { |order| number_to_currency(order.pst_amount) }
      row(:hst_amount) { |order| number_to_currency(order.hst_amount) }
      row(:total) { |order| number_to_currency(order.total) }
      row :created_at
    end

    panel "Products ordered" do
      table_for order.order_items do
        column :product_name
        column :sku
        column :quantity
        column(:unit_price) { |item| number_to_currency(item.unit_price) }
        column(:line_total) { |item| number_to_currency(item.line_total) }
      end
    end
  end
end
