ActiveAdmin.register Province do
  menu priority: 25, label: "Province Tax Rates"

  actions :index, :edit, :update
  permit_params :gst_rate, :pst_rate, :hst_rate

  config.filters = false
  config.sort_order = "name_asc"

  index title: "Canadian Province and Territory Tax Rates", download_links: false do
    column :name
    column :abbreviation
    column "GST" do |province|
      number_to_percentage(province.gst_rate * 100, precision: 3, strip_insignificant_zeros: true)
    end
    column "PST / QST" do |province|
      number_to_percentage(province.pst_rate * 100, precision: 3, strip_insignificant_zeros: true)
    end
    column "HST" do |province|
      number_to_percentage(province.hst_rate * 100, precision: 3, strip_insignificant_zeros: true)
    end
    actions defaults: false do |province|
      item "Edit tax rates", edit_admin_province_path(province), class: "member_link"
    end
  end

  form title: proc { |province| "Edit tax rates for #{province.name}" } do |form|
    form.semantic_errors
    form.inputs "Province or territory" do
      form.input :name, input_html: { disabled: true }
      form.input :abbreviation, input_html: { disabled: true }
    end
    form.inputs "Tax rates" do
      form.input :gst_rate,
        label: "GST rate",
        hint: "Enter a decimal rate, for example 0.05 for 5%.",
        input_html: { min: 0, max: 1, step: 0.00001 }
      form.input :pst_rate,
        label: "PST / QST rate",
        hint: "Enter a decimal rate, for example 0.07 for 7%.",
        input_html: { min: 0, max: 1, step: 0.00001 }
      form.input :hst_rate,
        label: "HST rate",
        hint: "Enter a decimal rate, for example 0.13 for 13%.",
        input_html: { min: 0, max: 1, step: 0.00001 }
    end
    form.actions
  end

  controller do
    def update
      super do |success, _failure|
        success.html do
          redirect_to admin_provinces_path,
            notice: "Tax rates for #{resource.name} were updated successfully."
        end
      end
    end
  end

  sidebar "How tax changes work", only: :edit do
    para "Rates entered here apply to new orders. Existing invoices keep the rates recorded when those orders were placed."
    para "Province names and abbreviations are protected so customer address associations remain valid."
  end
end
