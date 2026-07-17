class HomeController < ApplicationController
  def index
    @products = Product.available
      .includes(:category, image_attachment: :blob)
      .order(updated_at: :desc)
      .limit(6)
    @categories = Category.joins(:products)
      .merge(Product.available)
      .distinct
      .order(:name)
      .limit(6)
    @category_counts = Product.available
      .where(category_id: @categories.select(:id))
      .group(:category_id)
      .count
  end
end
