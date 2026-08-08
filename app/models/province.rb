class Province < ApplicationRecord
  has_many :users, dependent: :restrict_with_error
  has_many :customers, dependent: :restrict_with_error

  validates :name, :abbreviation, presence: true, uniqueness: true
  validates :gst_rate, :pst_rate, :hst_rate,
    numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 1 }

  def self.ransackable_attributes(_auth_object = nil)
    %w[abbreviation gst_rate hst_rate id name pst_rate]
  end
end
