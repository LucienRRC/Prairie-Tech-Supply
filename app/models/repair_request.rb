class RepairRequest < ApplicationRecord
  belongs_to :pickup_request

  enum :repair_status, {
    submitted: "submitted", diagnosing: "diagnosing", awaiting_approval: "awaiting_approval",
    repairing: "repairing", repaired: "repaired", returned: "returned", cancelled: "cancelled"
  }, default: :submitted, validate: true

  normalizes :device_type, :brand, :model, with: ->(value) { value.strip }

  validates :device_type, :problem_description, presence: true
  validates :device_type, :brand, :model, length: { maximum: 120 }, allow_blank: true
  validates :problem_description, length: { maximum: 5_000 }
  validates :estimated_price,
    numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 99_999_999.99 },
    allow_nil: true
end
