class UserAchievementSync < ApplicationRecord
  belongs_to :user

  validates :character_name, :realm, :region, presence: true

  # Sérialiser les IDs d'achievements avec JSON
  serialize :synced_achievement_ids, coder: JSON

  def achievement_ids
    synced_achievement_ids || []
  end

  def achievement_ids=(ids)
    self.synced_achievement_ids = ids
  end
end
