class Province < ApplicationRecord
  has_many :users, dependent: :restrict_with_error

  validates :name, :abbreviation, presence: true, uniqueness: true
  validates :gst_rate, :pst_rate, :hst_rate,
    numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 1 }
end
