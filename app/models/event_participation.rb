class EventParticipation < ApplicationRecord
  belongs_to :event
  belongs_to :character
  belongs_to :specialization, optional: true

  validates :character_id, uniqueness: { scope: :event_id, message: "déjà inscrit" }

  def active_specialization
    specialization || character.specialization
  end

  def role
    active_specialization&.role
  end
end
