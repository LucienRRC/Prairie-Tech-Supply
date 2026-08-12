class OrderItem < ApplicationRecord
  belongs_to :order
  belongs_to :product

  normalizes :product_name, with: ->(name) { name.strip }
  normalizes :sku, with: ->(sku) { sku.strip.upcase }

  validates :product_name, :sku, presence: true
  validates :product_name, length: { maximum: 120 }
  validates :sku,
    length: { maximum: 60 },
    format: {
      with: DataFormats::SKU,
      message: "must contain only letters, numbers, and single hyphens"
    }
  validates :quantity, numericality: { only_integer: true, greater_than: 0 }
  validates :unit_price, :line_total,
    numericality: { greater_than: 0, less_than_or_equal_to: 99_999_999.99 }
  validate :line_total_matches_quantity_and_price

  private

  def line_total_matches_quantity_and_price
    return if quantity.blank? || unit_price.blank? || line_total.blank?
    return unless quantity.to_i.positive? && unit_price.to_d.positive?
    return if line_total.to_d == (unit_price.to_d * quantity.to_i).round(2)

    errors.add(:line_total, "must equal quantity multiplied by unit price")
  end
end
