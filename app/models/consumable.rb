class Consumable < ApplicationRecord
  has_many :recipes, dependent: :destroy
  has_many :ingredients, through: :recipes

  validates :name, presence: true
  validates :blizzard_id, uniqueness: true, allow_nil: true
  validates :category, presence: true

  CATEGORIES = %w[potion flask food rune elixir augment].freeze

  scope :potions, -> { where(category: 'potion') }
  scope :flasks, -> { where(category: 'flask') }
  scope :food, -> { where(category: 'food') }
  scope :by_expansion, ->(expansion) { where(expansion: expansion) }

  # Méthode simplifiée : utilise seulement icon_name
  def icon_image_url
    return nil unless icon_name.present?
    "https://wow.zamimg.com/images/wow/icons/large/#{icon_name}.jpg"
  end

  def ingredients_with_quantities
    recipes.includes(:ingredient).each_with_object({}) do |recipe, hash|
      hash[recipe.ingredient] = recipe.quantity
    end
  end

  def craftable_quantity(week = Date.current.beginning_of_week)
    return 0 if ingredients.empty?

    ingredients_with_quantities.map do |ingredient, needed_qty|
      available = ingredient.total_farmed(week)
      (available / needed_qty).floor
    end.min
  end
end
