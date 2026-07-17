# frozen_string_literal: true
ActiveAdmin.register_page "Dashboard" do
  menu priority: 1, label: proc { I18n.t("active_admin.dashboard") }

  content title: proc { I18n.t("active_admin.dashboard") } do
    div class: "admin-welcome",
      style: "background-image: linear-gradient(90deg, rgba(7, 18, 35, .96), rgba(7, 38, 65, .72)), url('#{image_path("computer-technology.jpg")}')" do
      span "ADMIN CONTROL CENTER", class: "admin-welcome-label"
      h2 "Prairie Tech Supply"
      para "Manage products, inventory, product images, and public website content from one place."
    end

    div class: "admin-stats" do
      div class: "admin-stat" do
        strong Product.count
        span "Products"
      end
      div class: "admin-stat" do
        strong Product.where(active: true).count
        span "Active products"
      end
      div class: "admin-stat" do
        strong Product.where("stock_quantity <= ?", 10).count
        span "Low-stock items"
      end
      div class: "admin-stat" do
        strong SitePage.count
        span "Editable pages"
      end
    end

    div class: "admin-dashboard-grid" do
      div do
        panel "Low-stock products" do
          table_for Product.includes(:category).where("stock_quantity <= ?", 10).order(:stock_quantity).limit(8) do
            column("Product") { |product| link_to product.name, admin_product_path(product) }
            column :category
            column :stock_quantity
          end
        end
      end

      div do
        panel "Quick actions" do
          ul class: "admin-quick-links" do
            li link_to("Add a product", new_admin_product_path)
            li link_to("Manage products", admin_products_path)
            li link_to("Edit About & Contact", admin_site_pages_path)
            li link_to("View storefront", root_path, target: "_blank", rel: "noopener")
          end
        end
      end
    end
  end
end
