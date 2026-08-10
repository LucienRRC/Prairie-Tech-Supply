module ApplicationHelper
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
