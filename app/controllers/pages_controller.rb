class PagesController < ApplicationController
  skip_before_action :authenticate_user!, only: [ :home ]

  def home
    # Stats générales
    @members_count = User.count
    @active_characters_count = Character.permanent.count

    # Prochain event
    @next_event = Event.where('start_time >= ?', DateTime.now)
                      .order(:start_time)
                      .first
    @next_event_participants = @next_event&.event_participations&.count || 0

    # Progression raid (tu peux adapter cette logique selon tes besoins)
    # Par exemple, compter les events "raid" complétés vs total
    @raid_progress = calculate_raid_progress

    # Farm collectif - progression de la semaine actuelle
    @farm_progress = calculate_farm_progress

    # Activité récente
    @recent_participations = EventParticipation
                              .includes(character: [:user, :wow_class, :specialization], event: [])
                              .order(created_at: :desc)
                              .limit(5)

    @recent_characters = Character
                          .permanent
                          .includes(:user, :wow_class, :specialization)
                          .order(created_at: :desc)
                          .limit(5)

    # Contributions farm récentes (optionnel)
    @recent_contributions = FarmContribution
                             .current_week
                             .includes(:user, :ingredient)
                             .order(created_at: :desc)
                             .limit(5)
  end

  private

  def calculate_raid_progress
    # Exemple simple : retourne "7/8" ou adapte selon ta logique
    # Tu peux par exemple compter les boss down, ou avoir un champ dans Event
    raid_events = Event.where(event_type: 'raid')
    completed = raid_events.where('start_time < ?', DateTime.now).count
    total = raid_events.count

    "#{completed}/#{total}"
  end

  def calculate_farm_progress
    # Récupère tous les ingrédients avec leurs objectifs
    # et calcule le pourcentage global de farm de la semaine

    ingredients = Ingredient.all
    return 0 if ingredients.empty?

    total_progress = ingredients.map do |ingredient|
      # Objectif pour cet ingrédient (tu dois avoir un champ objective_quantity ou similaire)
      objective = ingredient.objective_quantity || 100

      # Quantité farmée cette semaine
      farmed = FarmContribution.current_week
                               .where(ingredient: ingredient)
                               .sum(:quantity)

      # Calcul du pourcentage pour cet ingrédient (max 100%)
      [(farmed.to_f / objective * 100).round, 100].min
    end

    # Moyenne des progressions
    (total_progress.sum / ingredients.count.to_f).round
  end
end
