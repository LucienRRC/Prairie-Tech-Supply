class Product < ApplicationRecord
  belongs_to :category
  has_many :cart_items, dependent: :destroy
  has_many :order_items, dependent: :restrict_with_error
  has_one_attached :image

  scope :available, -> { where(active: true).where("stock_quantity > 0") }
  scope :on_sale, -> { where.not(sale_price: nil).where("sale_price < price") }
  scope :new_arrivals, -> { where(created_at: 3.days.ago..Time.current) }
  scope :recently_updated, -> {
    where(updated_at: 3.days.ago..Time.current)
      .where("created_at < ?", 3.days.ago)
  }

  def self.search_by_keyword(keyword)
    normalized_keyword = keyword.to_s.strip.downcase
    return all if normalized_keyword.blank?

    pattern = "%#{sanitize_sql_like(normalized_keyword)}%"
    where(
      "LOWER(products.name) LIKE :pattern OR LOWER(products.description) LIKE :pattern",
      pattern: pattern
    )
  end

  validates :name, :sku, presence: true
  validates :sku, uniqueness: { case_sensitive: false }
  validates :price, numericality: { greater_than_or_equal_to: 0 }
  validates :sale_price,
    numericality: { greater_than_or_equal_to: 0, less_than: :price },
    allow_nil: true
  validates :stock_quantity, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  def on_sale?
    sale_price.present? && sale_price < price
  end

  def selling_price
    on_sale? ? sale_price : price
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[active brand category_id created_at id name price sale_price sku stock_quantity updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[category image_attachment image_blob]
  end
end
