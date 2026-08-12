class User < ApplicationRecord
  belongs_to :province
  has_one :cart, dependent: :destroy
  has_many :orders, dependent: :restrict_with_error
  has_many :pickup_requests, dependent: :restrict_with_error

  has_secure_password

  enum :role, { customer: "customer", admin: "admin" }, default: :customer, validate: true
  normalizes :email, with: ->(email) { email.strip.downcase }
  normalizes :first_name, :last_name, :address, :city, with: ->(value) { value.strip }
  normalizes :postal_code, with: ->(postal_code) { postal_code.strip.upcase }
  normalizes :phone, with: ->(phone) { phone.strip }

  validates :first_name, :last_name, presence: true
  validates :first_name, :last_name,
    length: { maximum: 60 },
    format: { with: DataFormats::NAME, message: "may only contain letters and common name punctuation" }
  validates :email,
    presence: true,
    uniqueness: { case_sensitive: false },
    length: { maximum: 254 },
    format: {
      with: DataFormats::EMAIL,
      message: "must be a complete email address, such as name@example.com"
    }
  validates :password,
    length: { minimum: 8, maximum: 72 },
    if: -> { new_record? || password.present? }
  validates :phone,
    length: { maximum: 25 },
    format: { with: DataFormats::PHONE, message: "must be a valid North American phone number" },
    allow_blank: true
  validates :postal_code,
    length: { maximum: 7 },
    format: { with: DataFormats::CANADIAN_POSTAL_CODE, message: "must be a valid Canadian postal code" },
    allow_blank: true
  validates :address, :city, length: { maximum: 120 }, allow_blank: true
end
