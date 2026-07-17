class CategoriesController < ApplicationController
  def index
    @categories = Category.joins(:products)
      .merge(Product.where(active: true))
      .distinct
      .order(:name)
    @product_counts = Product.where(active: true, category_id: @categories.select(:id))
      .group(:category_id)
      .count
  end

  def show
    @category = Category.find(params[:id])
    @products = @category.products
      .includes(image_attachment: :blob)
      .where(active: true)
      .order(:name)
      .page(params[:page])
      .per(6)
  end
end
