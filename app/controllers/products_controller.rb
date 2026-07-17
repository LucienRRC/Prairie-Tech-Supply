class ProductsController < ApplicationController
  def index
    @keyword = params[:keyword].to_s.strip
    @selected_category_id = params[:category_id].presence
    @categories = Category.order(:name)

    products = Product.includes(:category, image_attachment: :blob)
      .where(active: true)
      .search_by_keyword(@keyword)

    products = products.where(category_id: @selected_category_id) if @selected_category_id

    @products = products
      .order(:name)
      .page(params[:page])
      .per(6)
  end

  def show
    @product = Product.includes(:category, image_attachment: :blob).find(params[:id])
  end
end
