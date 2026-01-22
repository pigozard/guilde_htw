class FarmContribution < ApplicationRecord
  belongs_to :user
  belongs_to :ingredient

  validates :quantity, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :ingredient_id, uniqueness: { scope: [:user_id, :week], message: "déjà enregistré pour cette semaine" }

  scope :current_week, -> { where(week: Date.current.beginning_of_week) }
  scope :by_week, ->(week) { where(week: week) }

  before_validation :set_current_week, on: :create

  private

  def set_current_week
    self.week ||= Date.current.beginning_of_week
  end
end
