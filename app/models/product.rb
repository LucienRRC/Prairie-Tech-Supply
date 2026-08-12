class Product < ApplicationRecord
  IMAGE_CONTENT_TYPES = %w[image/jpeg image/png image/webp].freeze
  MAX_IMAGE_SIZE = 5.megabytes

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

  normalizes :name, :brand, with: ->(value) { value.strip }
  normalizes :sku, with: ->(sku) { sku.strip.upcase }

  validates :name, :description, :sku, presence: true
  validates :name, :brand, length: { maximum: 120 }, allow_blank: true
  validates :description, length: { maximum: 5_000 }
  validates :sku,
    uniqueness: { case_sensitive: false },
    length: { maximum: 60 },
    format: {
      with: DataFormats::SKU,
      message: "must contain only letters, numbers, and single hyphens"
    }
  validates :price, numericality: { greater_than: 0, less_than_or_equal_to: 99_999_999.99 }
  validates :sale_price,
    numericality: { greater_than: 0, less_than: :price, less_than_or_equal_to: 99_999_999.99 },
    allow_nil: true
  validates :stock_quantity,
    numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 2_147_483_647 }
  validates :active, inclusion: { in: [true, false] }
  validate :acceptable_image

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

  private

  def acceptable_image
    return unless image.attached?

    unless IMAGE_CONTENT_TYPES.include?(image.blob.content_type)
      errors.add(:image, "must be a JPG, PNG, or WebP file")
    end

    if image.blob.byte_size > MAX_IMAGE_SIZE
      errors.add(:image, "must be smaller than 5 MB")
    end
  end
end
