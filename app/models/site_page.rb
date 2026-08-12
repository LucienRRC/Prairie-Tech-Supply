class SitePage < ApplicationRecord
  EDITABLE_SLUGS = %w[about contact].freeze

  normalizes :slug, with: ->(slug) { slug.strip.downcase }
  normalizes :title, with: ->(title) { title.strip }

  validates :slug,
    presence: true,
    inclusion: { in: EDITABLE_SLUGS },
    uniqueness: { case_sensitive: false }
  validates :title, :body, presence: true
  validates :title, length: { maximum: 120 }
  validates :body, length: { maximum: 20_000 }

  def self.ransackable_attributes(_auth_object = nil)
    %w[body created_at id slug title updated_at]
  end
end
