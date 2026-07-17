class HomeController < ApplicationController
  def index
    @products = Product.includes(:category, image_attachment: :blob).where(active: true).limit(6)
  end
end
