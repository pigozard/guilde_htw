class Character < ApplicationRecord
  belongs_to :user
  belongs_to :wow_class, optional: true
  belongs_to :specialization, optional: true

  has_many :event_participations, dependent: :destroy
  has_many :events, through: :event_participations

  validates :pseudo, presence: true

  scope :permanent, -> { where(temporary: false) }
  scope :roster, -> { permanent.includes(:user, :wow_class, :specialization).order(created_at: :desc) }
  scope :with_class, -> { joins(:wow_class).where.not(wow_classes: { name: "Flex" }) }

  def self.role_counts
    permanent.joins(:specialization).group("specializations.role").count
  end

  def self.flex_count
    permanent.where(specialization_id: nil).count
  end
end
