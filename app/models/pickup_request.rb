class PickupRequest < ApplicationRecord
  belongs_to :user
  belongs_to :order, optional: true
  has_one :repair_request, dependent: :destroy

  enum :pickup_type, {
    in_store: "in_store", local_delivery: "local_delivery", repair_pickup: "repair_pickup"
  }, validate: true
  enum :status, {
    requested: "requested", confirmed: "confirmed", in_progress: "in_progress",
    completed: "completed", cancelled: "cancelled"
  }, default: :requested, validate: true

  normalizes :address, :city, with: ->(value) { value.strip }
  normalizes :postal_code, with: ->(postal_code) { postal_code.strip.upcase }

  validates :scheduled_at, presence: true
  validates :address, :city, length: { maximum: 120 }, allow_blank: true
  validates :postal_code,
    length: { maximum: 7 },
    format: { with: DataFormats::CANADIAN_POSTAL_CODE, message: "must be a valid Canadian postal code" },
    allow_blank: true
  validates :notes, length: { maximum: 2_000 }, allow_blank: true
  validate :delivery_address_is_present, unless: :in_store?

  private

  def delivery_address_is_present
    errors.add(:address, "is required for delivery or repair pickup") if address.blank?
    errors.add(:city, "is required for delivery or repair pickup") if city.blank?
    errors.add(:postal_code, "is required for delivery or repair pickup") if postal_code.blank?
  end
end
