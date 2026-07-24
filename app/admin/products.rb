ActiveAdmin.register Product do
  menu priority: 10, label: "Products"
  config.sort_order = "updated_at_desc"

  permit_params :category_id, :name, :description, :brand, :sku, :price,
    :sale_price, :stock_quantity, :active, :image

  includes :category, image_attachment: :blob

  filter :category,
    as: :select,
    collection: -> { Category.order(:name).pluck(:name, :id) },
    include_blank: "All categories"
  filter :active,
    as: :select,
    collection: [["Active", true], ["Inactive", false]],
    include_blank: "Any status"
  filter :price,
    as: :numeric,
    label: "Price (CAD)",
    filters: [:eq, :gteq, :lteq]

  scope :all, default: true
  scope("Active") { |products| products.where(active: true) }
  scope("Inactive") { |products| products.where(active: false) }
  scope("Low stock") { |products| products.where("stock_quantity <= ?", 10) }

  batch_action :mark_active do |ids|
    batch_action_collection.find(ids).each { |product| product.update!(active: true) }
    redirect_to collection_path, notice: "Selected products are now active."
  end

  batch_action :mark_inactive do |ids|
    batch_action_collection.find(ids).each { |product| product.update!(active: false) }
    redirect_to collection_path, notice: "Selected products are now inactive."
  end

  index download_links: false do
    selectable_column
    id_column
    column :image do |product|
      source = product.image.attached? ? url_for(product.image) : image_path("computer-technology.jpg")
      image_tag(source, class: "admin-product-thumb", alt: product.name)
    end
    column :name
    column :brand
    column :category
    column :sku
    column(:price) { |product| number_to_currency(product.price) }
    column :sale_price do |product|
      product.on_sale? ? number_to_currency(product.sale_price) : "—"
    end
    column :stock_quantity do |product|
      status_tag product.stock_quantity, class: product.stock_quantity <= 10 ? "warning" : "ok"
    end
    column :active do |product|
      status_tag(product.active? ? "Active" : "Inactive", class: product.active? ? "ok" : "error")
    end
    actions
  end

  show do
    attributes_table do
      row :image do |product|
        source = product.image.attached? ? url_for(product.image) : image_path("computer-technology.jpg")
        image_tag(source, class: "admin-product-preview", alt: product.name)
      end
      row :name
      row :brand
      row :category
      row :sku
      row :description
      row(:price) { |product| number_to_currency(product.price) }
      row(:sale_price) do |product|
        product.on_sale? ? number_to_currency(product.sale_price) : "Not on sale"
      end
      row :stock_quantity do |product|
        status_tag product.stock_quantity, class: product.stock_quantity <= 10 ? "warning" : "ok"
      end
      row :active do |product|
        status_tag(product.active? ? "Active" : "Inactive", class: product.active? ? "ok" : "error")
      end
      row :created_at
      row :updated_at
    end
  end

  form html: { multipart: true } do |f|
    f.semantic_errors
    f.inputs "Product details" do
      f.input :category
      f.input :name
      f.input :brand
      f.input :sku
      f.input :description, input_html: { rows: 7 }
      f.input :price, min: 0, step: 0.01
      f.input :sale_price,
        min: 0,
        max: 99_999_999.99,
        step: 0.01,
        hint: "Leave blank for regular pricing. Sale price must be lower than the regular price."
      f.input :stock_quantity, min: 0
      f.input :active
      current_image = f.object.image.attached? ? url_for(f.object.image) : image_path("computer-technology.jpg")
      f.input :image, as: :file,
        hint: safe_join([
          image_tag(current_image, class: "admin-product-preview", alt: "Current product image"),
          content_tag(:span, "Upload a JPG, PNG, or WebP image to replace the current image.", class: "admin-file-hint")
        ])
    end
    f.actions
  end
end
