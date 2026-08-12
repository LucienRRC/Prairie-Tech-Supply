class CartItem < ApplicationRecord
  belongs_to :cart
  belongs_to :product

  validates :product_id, uniqueness: { scope: :cart_id }
  validates :quantity, numericality: { only_integer: true, greater_than: 0 }
  validate :quantity_does_not_exceed_stock

  private

  def quantity_does_not_exceed_stock
    return if product.blank? || quantity.blank? || quantity.to_i <= product.stock_quantity

    errors.add(:quantity, "cannot exceed the available stock of #{product.stock_quantity}")
  end
end
