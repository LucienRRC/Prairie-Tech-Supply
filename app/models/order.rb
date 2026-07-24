class Order < ApplicationRecord
  belongs_to :customer
  belongs_to :user, optional: true
  has_many :order_items, dependent: :destroy
  has_one :pickup_request, dependent: :nullify

  enum :status, {
    pending: "pending", paid: "paid", processing: "processing",
    ready: "ready", completed: "completed", cancelled: "cancelled"
  }, default: :pending, validate: true

  enum :delivery_method, {
    in_store_pickup: "in_store_pickup", local_delivery: "local_delivery",
    shipping: "shipping"
  }, validate: true

  validates :recipient_name, :province_name, presence: true
  validates :subtotal, :gst_amount, :pst_amount, :hst_amount, :delivery_fee, :total,
    numericality: { greater_than_or_equal_to: 0 }
end
