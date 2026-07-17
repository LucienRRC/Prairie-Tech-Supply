ActiveAdmin.register AdminUser do
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
    f.inputs do
      f.input :username
      f.input :email
      f.input :password
      f.input :password_confirmation
    end
    f.actions
  end

end
