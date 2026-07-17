class OrderItem < ApplicationRecord
  belongs_to :order
  belongs_to :product

  validates :product_name, :sku, presence: true
  validates :quantity, numericality: { only_integer: true, greater_than: 0 }
  validates :unit_price, :line_total, numericality: { greater_than_or_equal_to: 0 }
end
