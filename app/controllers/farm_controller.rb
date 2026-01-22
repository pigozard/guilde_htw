class FarmController < ApplicationController
  before_action :authenticate_user!

  def index
    @current_week = Date.current.beginning_of_week

    # Toutes les sélections de la semaine (tous les joueurs)
    @all_selections = ConsumableSelection.current_week.includes(:consumable, :user)

    # Résumé par consumable (combien de fois choisi)
    @consumables_summary = @all_selections.group(:consumable_id).sum(:quantity)

    # Calcul des ingrédients nécessaires (PRIORITÉ)
    @ingredients_needed = calculate_ingredients_needed

    # Tous les consumables pour la recherche
    @all_consumables = Consumable.includes(recipes: :ingredient).order(:category, :name)

    # Mes sélections perso
    @my_selections = current_user.consumable_selections.current_week.includes(:consumable)
  end

  private

  def calculate_ingredients_needed
    summary = {}

    # Pour chaque sélection, on additionne les ingrédients nécessaires
    @all_selections.each do |selection|
      selection.consumable.recipes.each do |recipe|
        ingredient = recipe.ingredient
        needed_qty = recipe.quantity * selection.quantity

        summary[ingredient] ||= { needed: 0, farmed: 0 }
        summary[ingredient][:needed] += needed_qty
      end
    end

    # Ajoute les quantités farmées
    summary.each do |ingredient, data|
      data[:farmed] = ingredient.total_farmed(@current_week)
      data[:percentage] = data[:needed].zero? ? 100 : ((data[:farmed].to_f / data[:needed]) * 100).round(1)
      data[:status] = status_for_percentage(data[:percentage])
    end

    # Trie par priorité (les plus critiques en premier)
    summary.sort_by { |_, data| data[:percentage] }.to_h
  end

  def status_for_percentage(percentage)
    case percentage
    when 0...40 then 'critical'
    when 40...80 then 'warning'
    else 'ok'
    end
  end
end
