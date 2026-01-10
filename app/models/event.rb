class Event < ApplicationRecord
  belongs_to :user
  has_many :event_participations, dependent: :destroy
  has_many :characters, through: :event_participations

  validates :title, presence: true
  validates :start_time, presence: true

  def event_type_emoji
    case event_type
    when "raid" then "⚔️"
    when "mythic+" then "🔑"
    when "pvp" then "🛡️"
    when "social" then "🎉"
    else "📅"
    end
  end

  def event_type_label
    case event_type
    when "raid" then "Raid"
    when "mythic+" then "Mythic+"
    when "pvp" then "PvP"
    when "social" then "Social"
    else "Autre"
    end
  end

  def confirmed_count
    event_participations.where(status: "confirmed").count
  end

  def participation_for(character)
    event_participations.find_by(character: character)
  end
end
