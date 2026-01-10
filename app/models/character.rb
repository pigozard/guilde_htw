class Character < ApplicationRecord
  belongs_to :user
  belongs_to :wow_class, optional: true
  belongs_to :specialization, optional: true

  has_many :event_participations, dependent: :destroy
  has_many :events, through: :event_participations

  validates :pseudo, presence: true
end
