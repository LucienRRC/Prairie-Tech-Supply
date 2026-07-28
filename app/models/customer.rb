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

  validates :first_name, :last_name, presence: true
  validates :username, presence: true, if: :account_registered?
  validates :username,
    uniqueness: { case_sensitive: false },
    format: {
      with: /\A[a-zA-Z0-9_.-]+\z/,
      message: "may only contain letters, numbers, dots, underscores, and hyphens"
    },
    allow_blank: true
  validates :email,
    presence: true,
    uniqueness: { case_sensitive: false },
    format: { with: URI::MailTo::EMAIL_REGEXP }

  def password_required?
    account_registered? && super
  end

  def active_for_authentication?
    super && account_registered?
  end
end
