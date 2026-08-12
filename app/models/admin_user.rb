class AdminUser < ApplicationRecord
  USERNAME_FORMAT = /\A[a-zA-Z0-9_.-]+\z/

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, 
         :recoverable, :rememberable, :validatable,
         authentication_keys: [:username]

  normalizes :username, with: ->(username) { username.strip.downcase }

  validates :username,
    presence: true,
    uniqueness: { case_sensitive: false },
    length: { in: 3..40 },
    format: {
      with: USERNAME_FORMAT,
      message: "may only contain letters, numbers, dots, underscores, and hyphens"
    }

  def self.ransackable_attributes(_auth_object = nil)
    %w[created_at email id username]
  end
end
