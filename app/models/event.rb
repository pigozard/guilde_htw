class Event < ApplicationRecord
  belongs_to :user
  has_many :event_participations, dependent: :destroy
  has_many :characters, through: :event_participations

  EVENT_TYPES_DATA = {
    "raid" => { emoji: "⚔️", label: "Raid" },
    "mythic+" => { emoji: "🔑", label: "Mythic+" },
    "pvp" => { emoji: "🛡️", label: "PvP" },
    "social" => { emoji: "🎉", label: "Social" },
    "other" => { emoji: "📅", label: "Autre" }
  }.freeze

  EVENT_TYPES = EVENT_TYPES_DATA.keys.freeze

  validates :title, presence: true
  validates :start_time, presence: true
  validates :event_type, inclusion: { in: EVENT_TYPES }, allow_blank: true

  def event_type_emoji
    EVENT_TYPES_DATA.dig(event_type, :emoji) || "📅"
  end

  def event_type_label
    EVENT_TYPES_DATA.dig(event_type, :label) || "Autre"
  end

  def confirmed_count
    event_participations.where(status: "confirmed").count
  end

  def participation_for(character)
    event_participations.find_by(character: character)
  end
end
