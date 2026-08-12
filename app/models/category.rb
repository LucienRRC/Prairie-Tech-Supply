class Category < ApplicationRecord
  has_many :products, dependent: :restrict_with_error

  normalizes :name, with: ->(name) { name.strip }

  validates :name,
    presence: true,
    uniqueness: { case_sensitive: false },
    length: { maximum: 80 }
  validates :description, length: { maximum: 1_000 }, allow_blank: true
end
