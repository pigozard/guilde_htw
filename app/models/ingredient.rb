class Ingredient < ApplicationRecord
  has_many :recipes, dependent: :destroy
  has_many :consumables, through: :recipes
  has_many :farm_contributions, dependent: :destroy
  has_many :farmer_assignments, dependent: :destroy

  validates :name, presence: true
  validates :blizzard_id, uniqueness: true, allow_nil: true

  CATEGORIES = %w[herb ore meat fish leather cloth essence].freeze

  scope :herbs, -> { where(category: 'herb') }
  scope :ores, -> { where(category: 'ore') }
  scope :by_category, ->(category) { where(category: category) }

  # Total farmé pour cet ingrédient (cette semaine)
  def total_farmed(week = Date.current.beginning_of_week)
    farm_contributions.where(week: week).sum(:quantity)
  end

  # Total nécessaire pour tous les consommables qui utilisent cet ingrédient
  def total_needed(target_consumables = 20, week = Date.current.beginning_of_week)
    recipes.sum { |recipe| recipe.quantity * target_consumables }
  end

  # Pourcentage de progression du farm
  def farm_progress(target_consumables = 20, week = Date.current.beginning_of_week)
    needed = total_needed(target_consumables, week)
    return 100 if needed.zero?

    farmed = total_farmed(week)
    ((farmed.to_f / needed) * 100).round(1)
  end

  # État du farm : ok, warning, critical
  def farm_status(target_consumables = 20, week = Date.current.beginning_of_week)
    progress = farm_progress(target_consumables, week)

    case progress
    when 80..Float::INFINITY then 'ok'
    when 40...80 then 'warning'
    else 'critical'
    end
  end
end
