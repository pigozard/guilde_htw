class ConsumableSelection < ApplicationRecord
  belongs_to :user
  belongs_to :consumable

  validates :quantity, presence: true, numericality: { greater_than: 0 }
  validates :consumable_id, uniqueness: { scope: [:user_id, :week] }

  scope :current_week, -> { where(week: Date.current.beginning_of_week) }
  scope :by_week, ->(week) { where(week: week) }

  before_validation :set_current_week, on: :create

  private

  def set_current_week
    self.week ||= Date.current.beginning_of_week
  end
end
