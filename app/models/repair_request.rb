class RepairRequest < ApplicationRecord
  belongs_to :pickup_request

  enum :repair_status, {
    submitted: "submitted", diagnosing: "diagnosing", awaiting_approval: "awaiting_approval",
    repairing: "repairing", repaired: "repaired", returned: "returned", cancelled: "cancelled"
  }, default: :submitted, validate: true

  validates :device_type, :problem_description, presence: true
  validates :estimated_price, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
end
