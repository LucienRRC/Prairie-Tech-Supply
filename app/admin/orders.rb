ActiveAdmin.register Order do
  menu priority: 20, label: "Order History"
  actions :index, :show
  config.sort_order = "created_at_desc"
  config.filters = false

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
      status_tag order.status.humanize
    end
    column("Ordered") { |order| order.created_at.in_time_zone.to_fs(:short) }
    actions defaults: false do |order|
      item "Invoice details", admin_order_path(order), class: "member_link"
    end
  end

  show title: proc { |order| "Order ##{order.id.to_s.rjust(6, '0')}" } do
    attributes_table do
      row :customer do |order|
        "#{order.recipient_name} - #{order.customer.email}"
      end
      row :province_name
      row :status
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
