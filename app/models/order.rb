class Order < ApplicationRecord
  belongs_to :customer
  belongs_to :user, optional: true
  has_many :order_items, dependent: :destroy
  has_one :pickup_request, dependent: :nullify

  enum :status, {
    new_order: "new", paid: "paid", shipped: "shipped", cancelled: "cancelled"
  }, default: :new_order, validate: true

  enum :delivery_method, {
    in_store_pickup: "in_store_pickup", local_delivery: "local_delivery",
    shipping: "shipping"
  }, validate: true

  validates :recipient_name, :province_name, presence: true
  validates :subtotal, :gst_amount, :pst_amount, :hst_amount, :delivery_fee, :total,
    numericality: { greater_than_or_equal_to: 0 }

  def status_label
    new_order? ? "New" : status.humanize
  end

  def mark_shipped!
    with_lock do
      errors.add(:status, "must be paid before it can be shipped") unless paid?
      raise ActiveRecord::RecordInvalid, self if errors.any?

      update!(status: :shipped, shipped_at: Time.current)
    end
  end

  def cancel_and_release_inventory!
    with_lock do
      return unless new_order?

      order_items.includes(:product).each do |item|
        item.product.with_lock do
          item.product.update!(stock_quantity: item.product.stock_quantity + item.quantity)
        end
      end
      update!(status: :cancelled)
    end
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[created_at customer_id delivery_method id paid_at province_name shipped_at status total updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[customer order_items]
  end
end
