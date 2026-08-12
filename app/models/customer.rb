class Customer < ApplicationRecord
  devise :database_authenticatable,
    :registerable,
    :validatable,
    authentication_keys: [:username],
    case_insensitive_keys: [:username]

  belongs_to :province
  has_many :orders, dependent: :restrict_with_error

  normalizes :username, with: ->(username) { username.strip.downcase }
  normalizes :email, with: ->(email) { email.strip.downcase }
  normalizes :first_name, :last_name, :city, with: ->(value) { value.strip }
  normalizes :postal_code, with: ->(postal_code) { postal_code.strip.upcase }
  normalizes :phone, with: ->(phone) { phone.strip }

  validates :first_name, :last_name, presence: true
  validates :first_name, :last_name,
    length: { maximum: 60 },
    format: { with: DataFormats::NAME, message: "may only contain letters and common name punctuation" }
  validates :username, presence: true, if: :account_registered?
  validates :username,
    uniqueness: { case_sensitive: false },
    length: { in: 3..40 },
    format: {
      with: /\A[a-zA-Z0-9_.-]+\z/,
      message: "may only contain letters, numbers, dots, underscores, and hyphens"
    },
    allow_blank: true
  validates :email,
    presence: true,
    uniqueness: { case_sensitive: false },
    length: { maximum: 254 },
    format: {
      with: DataFormats::EMAIL,
      message: "must be a complete email address, such as name@example.com"
    }
  validates :phone,
    length: { maximum: 25 },
    format: { with: DataFormats::PHONE, message: "must be a valid North American phone number" },
    allow_blank: true
  validates :postal_code,
    length: { maximum: 7 },
    format: { with: DataFormats::CANADIAN_POSTAL_CODE, message: "must be a valid Canadian postal code" },
    allow_blank: true
  validates :address, :city, length: { maximum: 120 }, allow_blank: true
  validates :account_registered, inclusion: { in: [true, false] }

  def password_required?
    account_registered? && super
  end

  def active_for_authentication?
    super && account_registered?
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[email first_name id last_name province_id username]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[orders province]
  end
end
