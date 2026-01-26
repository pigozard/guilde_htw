class FarmerAssignment < ApplicationRecord
  belongs_to :user
  belongs_to :ingredient

  validates :user_id, uniqueness: { scope: [:ingredient_id, :week] }

  scope :current_week, -> { where(week: Date.current.beginning_of_week) }
  scope :by_week, ->(week) { where(week: week) }

  before_validation :set_current_week, on: :create

  private

  def set_current_week
    self.week ||= Date.current.beginning_of_week
  end
end
