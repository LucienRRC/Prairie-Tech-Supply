ActiveAdmin.register Product do
  permit_params :category_id, :name, :description, :brand, :sku, :price,
    :stock_quantity, :active, :image

  includes :category, image_attachment: :blob

  filter :name
  filter :brand
  filter :sku
  filter :category
  filter :active

  scope :all, default: true
  scope("Active") { |products| products.where(active: true) }
  scope("Inactive") { |products| products.where(active: false) }
  scope("Low stock") { |products| products.where("stock_quantity <= ?", 10) }

  index do
    selectable_column
    id_column
    column :image do |product|
      image_tag(url_for(product.image), class: "admin-product-thumb") if product.image.attached?
    end
    column :name
    column :brand
    column :category
    column :sku
    column(:price) { |product| number_to_currency(product.price) }
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
        image_tag(url_for(product.image), class: "admin-product-preview") if product.image.attached?
      end
      row :name
      row :brand
      row :category
      row :sku
      row :description
      row(:price) { |product| number_to_currency(product.price) }
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
      f.input :stock_quantity, min: 0
      f.input :active
      f.input :image, as: :file, hint: (
        image_tag(url_for(f.object.image), class: "admin-product-preview") if f.object.image.attached?
      )
    end
    f.actions
  end
end
