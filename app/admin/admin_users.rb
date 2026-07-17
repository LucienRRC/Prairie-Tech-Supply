ActiveAdmin.register AdminUser do
  menu priority: 90, label: "Administrators"
  permit_params :username, :email, :password, :password_confirmation

  index do
    selectable_column
    id_column
    column :username
    column :email
    column :created_at
    actions
  end

  config.filters = false

  form do |f|
    f.semantic_errors
    f.inputs "Administrator account" do
      f.input :username
      f.input :email
      f.input :password, hint: ("Leave blank to keep the current password." if f.object.persisted?)
      f.input :password_confirmation
    end
    f.actions
  end
end
