class Character < ApplicationRecord
  belongs_to :user
  belongs_to :wow_class, optional: true
  belongs_to :specialization, optional: true

  has_many :event_participations, dependent: :destroy
  has_many :events, through: :event_participations

  validates :pseudo, presence: true

  scope :permanent, -> { where(temporary: false) }
  scope :roster, -> { permanent.where(in_roster: true).includes(:user, :wow_class, :specialization).order(created_at: :desc) }
  scope :out_of_roster, -> { permanent.where(in_roster: false) }
  scope :with_class, -> { joins(:wow_class).where.not(wow_classes: { name: "Flex" }) }

  def self.role_counts
    permanent.where(in_roster: true).joins(:specialization).group("specializations.role").count
  end

  def self.flex_count
    permanent.where(in_roster: true, specialization_id: nil).count
  end

  def self.class_counts
    all_classes = WowClass.all.pluck(:name)
    counts = permanent.where(in_roster: true).joins(:wow_class)
                      .group("wow_classes.name")
                      .count

    all_classes.each_with_object({}) do |name, hash|
      hash[name] = counts[name] || 0
    end
  end

end
