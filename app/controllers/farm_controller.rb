class FarmController < ApplicationController
  before_action :authenticate_user!

  def index
    @current_week = Date.current.beginning_of_week

    # Toutes les potions disponibles (pour la section recherche)
    @all_consumables = Consumable.includes(recipes: :ingredient).order(:category, :name)

    # Sélections de TOUS les joueurs cette semaine
    @consumable_selections = ConsumableSelection
      .current_week
      .includes(:consumable, :user)
      .order('consumables.name')

    # Grouper par consumable
    @selections_by_consumable = @consumable_selections.group_by(&:consumable)

    # Calcul des ingrédients nécessaires basé sur les sélections
    @ingredients_summary = calculate_ingredients_from_selections

    # Assignments des farmers
    @farmer_assignments = FarmerAssignment.current_week.includes(:user, :ingredient)
  end

  private

  def calculate_ingredients_from_selections
    summary = {}

    # Pour chaque ingrédient
    Ingredient.includes(:recipes, :farmer_assignments).find_each do |ingredient|
      needed = 0

      # Calcule le total nécessaire basé sur les sélections
      @selections_by_consumable.each do |consumable, selections|
        total_quantity = selections.sum(&:quantity)
        recipe = consumable.recipes.find_by(ingredient: ingredient)
        needed += (recipe.quantity * total_quantity) if recipe
      end

      # Skip si pas nécessaire
      next if needed.zero?

      # Qui farm cet ingrédient ?
      farmers = ingredient.farmer_assignments.current_week.includes(:user).map(&:user)

      # Pourcentage (on considère 0% pour l'instant, tu pourras ajouter un système de validation plus tard)
      percentage = 0

      summary[ingredient] = {
        needed: needed,
        farmed: 0,
        percentage: percentage,
        status: status_for_percentage(percentage),
        farmers: farmers
      }
    end

    # Trie par priorité (les plus critiques en premier)
    summary.sort_by { |_, data| [data[:percentage], -data[:needed]] }.to_h
  end

  def status_for_percentage(percentage)
    case percentage
    when 0...40 then 'critical'
    when 40...80 then 'warning'
    else 'ok'
    end
  end
end
