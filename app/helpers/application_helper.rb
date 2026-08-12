module ApplicationHelper
  def storefront_nav_link(label, path, section: nil)
    section ||= path
    active = case section
    when :products
      controller_path == "products"
    when :categories
      controller_path == "categories"
    when :about
      controller_path == "site_pages" && params[:slug] == "about"
    when :contact
      controller_path == "site_pages" && params[:slug] == "contact"
    when :cart
      controller_path.in?(["carts", "checkouts"])
    when :orders
      controller_path == "orders"
    when :account
      controller_path.start_with?("devise/")
    else
      current_page?(path)
    end

    link_to label, path,
      class: class_names("nav-link", "is-active": active),
      aria: (active ? { current: "page" } : {})
  end

  def breadcrumb_items
    items = [{ label: "Home", path: root_path }]

    case controller_path
    when "products"
      if action_name == "show" && @product
        items.concat([
          { label: "Categories", path: categories_path },
          { label: @product.category.name, path: category_path(@product.category) },
          { label: @product.name }
        ])
      else
        items << { label: "Products" }
      end
    when "categories"
      items << { label: "Categories", path: action_name == "show" ? categories_path : nil }
      items << { label: @category.name } if action_name == "show" && @category
    when "carts"
      items << { label: "Cart" }
    when "checkouts"
      items.concat([{ label: "Cart", path: cart_path }, { label: "Checkout" }])
    when "orders"
      items << { label: "Orders", path: action_name == "show" ? orders_path : nil }
      items << { label: "Invoice ##{@order.id.to_s.rjust(6, '0')}" } if action_name == "show" && @order
    when "site_pages"
      items << { label: @site_page&.title || params[:slug].to_s.humanize }
    else
      return []
    end

    items
  end
end
