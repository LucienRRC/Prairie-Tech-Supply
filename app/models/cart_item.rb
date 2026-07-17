class CartItem < ApplicationRecord
  belongs_to :cart
  belongs_to :product

  validates :product_id, uniqueness: { scope: :cart_id }
  validates :quantity, numericality: { only_integer: true, greater_than: 0 }
end
