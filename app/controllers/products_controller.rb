class ProductsController < ApplicationController
  FILTER_OPTIONS = [
    ["All products", ""],
    ["New arrivals (last 3 days)", "new"],
    ["Recently updated (last 3 days)", "recently_updated"]
  ].freeze

  def index
    @keyword = params[:keyword].to_s.strip
    @selected_category_id = params[:category_id].presence
    @selected_filter = params[:filter].presence_in(%w[new recently_updated])
    @filter_options = FILTER_OPTIONS
    @categories = Category.order(:name)

    products = Product.includes(:category, image_attachment: :blob)
      .available
      .search_by_keyword(@keyword)

    products = products.where(category_id: @selected_category_id) if @selected_category_id
    products = products.new_arrivals if @selected_filter == "new"
    products = products.recently_updated if @selected_filter == "recently_updated"

    @products = products
      .order(:name)
      .page(params[:page])
      .per(6)
  end

  def show
    @product = Product.includes(:category, image_attachment: :blob).find(params[:id])
  end
end
