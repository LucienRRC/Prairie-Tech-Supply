class ProductsController < ApplicationController
  def index
    @products = Product.includes(:category, image_attachment: :blob).where(active: true).order(:name)
  end

  def show
    @product = Product.includes(:category, image_attachment: :blob).find(params[:id])
  end
end
