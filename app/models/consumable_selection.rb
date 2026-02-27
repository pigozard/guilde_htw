class ConsumableSelection < ApplicationRecord
  belongs_to :user
  belongs_to :consumable

  validates :quantity, presence: true, numericality: { greater_than: 0 }
  validates :consumable_id, uniqueness: { scope: [:user_id, :week] }

  scope :current_week, -> { where(week: Date.current.beginning_of_week) }
  scope :by_week, ->(week) { where(week: week) }

  after_destroy :cleanup_orphaned_farm_data

  before_validation :set_current_week, on: :create

  private

  def set_current_week
    self.week ||= Date.current.beginning_of_week
  end

  def cleanup_orphaned_farm_data
    # Récupère les ingrédients de ce consommable
    ingredient_ids = consumable.ingredient_ids

    ingredient_ids.each do |ingredient_id|
      # Vérifie si cet ingrédient est encore nécessaire pour d'autres sélections de la même semaine
      still_needed = ConsumableSelection
        .where(week: week)
        .where.not(id: id)
        .joins(consumable: :recipes)
        .where(recipes: { ingredient_id: ingredient_id })
        .exists?

      unless still_needed
        # Supprime les contributions et assignations orphelines pour cette semaine
        FarmContribution.where(ingredient_id: ingredient_id, week: week).destroy_all
        FarmerAssignment.where(ingredient_id: ingredient_id, week: week).destroy_all
      end
    end
  end
end
