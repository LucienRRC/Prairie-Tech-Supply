ActiveAdmin.register SitePage do
  menu label: "About & Contact"
  permit_params :title, :body
  actions :index, :show, :edit, :update
  config.filters = false

  index do
    id_column
    column :title
    column :slug
    column :updated_at
    actions defaults: false do |page|
      item "View", resource_path(page)
      item "Edit", edit_resource_path(page)
    end
  end

  show do
    attributes_table do
      row :title
      row :slug
      row :body do |page|
        simple_format page.body
      end
      row :updated_at
    end
  end

  form do |f|
    f.semantic_errors
    f.inputs "Page content" do
      f.input :title
      f.input :body, as: :text, input_html: { rows: 16 }
    end
    f.actions
  end
end
