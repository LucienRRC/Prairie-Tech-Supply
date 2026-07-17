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

  validates :scheduled_at, presence: true
end
