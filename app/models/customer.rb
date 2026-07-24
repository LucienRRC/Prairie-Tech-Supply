class Customer < ApplicationRecord
  belongs_to :province
  has_many :orders, dependent: :restrict_with_error

  normalizes :email, with: ->(email) { email.strip.downcase }

  validates :first_name, :last_name, presence: true
  validates :email,
    presence: true,
    uniqueness: { case_sensitive: false },
    format: { with: URI::MailTo::EMAIL_REGEXP }
end
