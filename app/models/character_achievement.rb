class CharacterAchievement < ApplicationRecord
  belongs_to :character
  belongs_to :achievement

  validates :character_id, uniqueness: { scope: :achievement_id }

  scope :completed, -> { where(completed: true) }
  scope :incomplete, -> { where(completed: false) }
end
