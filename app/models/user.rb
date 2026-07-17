class User < ApplicationRecord
  belongs_to :province
  has_one :cart, dependent: :destroy
  has_many :orders, dependent: :restrict_with_error
  has_many :pickup_requests, dependent: :restrict_with_error

  has_secure_password

  enum :role, { customer: "customer", admin: "admin" }, default: :customer, validate: true
  normalizes :email, with: ->(email) { email.strip.downcase }

  validates :first_name, :last_name, presence: true
  validates :email, presence: true, uniqueness: { case_sensitive: false },
    format: { with: URI::MailTo::EMAIL_REGEXP }
end
