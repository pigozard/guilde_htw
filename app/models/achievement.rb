class Achievement < ApplicationRecord
  belongs_to :expansion
  has_many :character_achievements, dependent: :destroy
  has_many :characters, through: :character_achievements

  validates :blizzard_id, :name, presence: true
  validates :blizzard_id, uniqueness: true

  # Scopes
  scope :by_expansion, ->(expansion_id) { where(expansion_id: expansion_id) }
  scope :ordered_by_name, -> { order(:name) }
  scope :ordered_by_category, -> { order(:category, :name) }
  scope :not_feats_of_strength, -> { where(is_feat_of_strength: [false, nil]) }

  # Scopes par tag
  scope :pvp, -> { where(tags: 'pvp').where(is_feat_of_strength: [false, nil]) }
  scope :professions, -> { where(tags: 'professions').where(is_feat_of_strength: [false, nil]) }
  scope :pets, -> { where(tags: 'pets').where(is_feat_of_strength: [false, nil]) }
  scope :events, -> { where(tags: 'events').where(is_feat_of_strength: [false, nil]) }
  scope :collections, -> { where(tags: 'collections').where(is_feat_of_strength: [false, nil]) }
  scope :exploration, -> { where(tags: 'exploration').where(is_feat_of_strength: [false, nil]) }
  scope :normal, -> { where(tags: nil).where(is_feat_of_strength: [false, nil]) }

  def icon_url
    return nil unless icon.present?
    "https://render.worldofwarcraft.com/eu/icons/56/#{icon}.jpg"
  end

  def self.stats_for_user(synced_achievement_ids, scope_relation = all)
    total = scope_relation.count
    return nil if total == 0

    completed = scope_relation.where(blizzard_id: synced_achievement_ids).count
    remaining = total - completed
    percentage = (completed.to_f / total * 100).round(1)

    {
      total: total,
      completed: completed,
      remaining: remaining,
      percentage: percentage
    }
  end

  # Grouper par catégorie avec stats
  def self.grouped_by_category_with_stats(synced_achievement_ids)
    grouped = group(:category).count

    grouped.map do |category, total|
      completed = where(category: category, blizzard_id: synced_achievement_ids).count
      {
        category: category,
        total: total,
        completed: completed,
        remaining: total - completed,
        percentage: (completed.to_f / total * 100).round(1)
      }
    end.sort_by { |g| [-g[:remaining], g[:category]] }
  end
end
