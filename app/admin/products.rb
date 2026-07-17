ActiveAdmin.register Product do
  permit_params :category_id, :name, :description, :brand, :sku, :price,
    :stock_quantity, :active, :image

  includes :category, image_attachment: :blob

  filter :name
  filter :brand
  filter :sku
  filter :category
  filter :active

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
    column :price
    column :stock_quantity
    column :active
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
      row :price
      row :stock_quantity
      row :active
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
      f.input :description
      f.input :price
      f.input :stock_quantity
      f.input :active
      f.input :image, as: :file, hint: (
        image_tag(url_for(f.object.image), class: "admin-product-preview") if f.object.image.attached?
      )
    end
    f.actions
  end
end
