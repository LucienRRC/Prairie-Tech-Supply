class Province < ApplicationRecord
  has_many :users, dependent: :restrict_with_error
  has_many :customers, dependent: :restrict_with_error

  normalizes :name, with: ->(name) { name.strip }
  normalizes :abbreviation, with: ->(abbreviation) { abbreviation.strip.upcase }

  validates :name, :abbreviation, presence: true, uniqueness: { case_sensitive: false }
  validates :name, length: { maximum: 80 }
  validates :abbreviation,
    length: { is: 2 },
    format: { with: /\A[A-Z]{2}\z/, message: "must contain two uppercase letters" }
  validates :gst_rate, :pst_rate, :hst_rate,
    numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 1 }
  validate :hst_is_not_combined_with_separate_taxes

  def self.ransackable_attributes(_auth_object = nil)
    %w[abbreviation gst_rate hst_rate id name pst_rate]
  end

  private

  def hst_is_not_combined_with_separate_taxes
    return unless hst_rate.to_d.positive? && (gst_rate.to_d.positive? || pst_rate.to_d.positive?)

    errors.add(:hst_rate, "cannot be combined with GST or PST")
  end
end
