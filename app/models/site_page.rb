class SitePage < ApplicationRecord
  EDITABLE_SLUGS = %w[about contact].freeze

  validates :slug, presence: true, inclusion: { in: EDITABLE_SLUGS }, uniqueness: true
  validates :title, :body, presence: true
  validates :title, length: { maximum: 120 }
  validates :body, length: { maximum: 20_000 }

  def self.ransackable_attributes(_auth_object = nil)
    %w[body created_at id slug title updated_at]
  end
end
