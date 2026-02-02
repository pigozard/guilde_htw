class AchievementsController < ApplicationController
  before_action :authenticate_user!
  before_action :load_sync_data, only: [:index]

  def index
    @expansions = Expansion.ordered.includes(:achievements)

    # Type de vue : overview, expansion, pvp, professions, pets, collections, exploration, events
    @view_type = params[:view_type] || 'overview'
    @selected_expansion = params[:expansion_id] ? Expansion.find(params[:expansion_id]) : nil
    @selected_category = params[:category]
    @show_completed = params[:show_completed] == 'true'

    if @user_sync
      @character_name = @user_sync.character_name
      @realm = @user_sync.realm
      @region = @user_sync.region
      @synced_achievements = @user_sync.achievement_ids

      case @view_type
      when 'overview'
        calculate_overview_stats
      when 'expansion'
        load_expansion_achievements if @selected_expansion
      when 'pvp'
        load_special_category_achievements(Achievement.pvp, '⚔️ PvP')
      when 'professions'
        load_special_category_achievements(Achievement.professions, '🔨 Métiers')
      when 'pets'
        load_special_category_achievements(Achievement.pets, '🐾 Mascottes')
      when 'collections'
        load_special_category_achievements(Achievement.collections, '🎨 Collections')
      when 'exploration'
        load_special_category_achievements(Achievement.exploration, '🗺️ Exploration')
      when 'events'
        load_special_category_achievements(Achievement.events, '🎉 Événements')
      end
    end
  end

  def sync
    character_name = params[:character_name]
    realm = params[:realm]
    region = params[:region] || 'eu'

    if character_name.blank? || realm.blank?
      redirect_to achievements_path, alert: "Veuillez remplir le nom du personnage et le serveur."
      return
    end

    service = BlizzardApiService.new(region: region)

    unless service.authenticate
      redirect_to achievements_path, alert: "Erreur d'authentification avec l'API Blizzard."
      return
    end

    data = service.get_character_achievements(realm, character_name)

    if data.nil?
      redirect_to achievements_path, alert: "Personnage introuvable. Vérifiez le nom et le serveur."
      return
    end

    completed_ids = extract_completed_achievement_ids(data)

    user_sync = current_user.user_achievement_syncs.find_or_initialize_by(
      character_name: character_name,
      realm: realm
    )

    user_sync.region = region
    user_sync.achievement_ids = completed_ids
    user_sync.synced_at = Time.current
    user_sync.save!

    redirect_to achievements_path, notice: "✅ #{completed_ids.count} hauts faits synchronisés !"
  end

  private

  def load_sync_data
    @user_sync = current_user.user_achievement_syncs.order(synced_at: :desc).first
  end

  def calculate_overview_stats
    # Stats par extension
    @expansion_stats = @expansions.map do |expansion|
      achievements_scope = expansion.achievements.normal
      stats = Achievement.stats_for_user(@synced_achievements, achievements_scope)
      next if stats.nil?

      stats.merge(expansion: expansion)
    end.compact

    # Stats par catégorie spéciale
    @pvp_stats = Achievement.stats_for_user(@synced_achievements, Achievement.pvp)
    @professions_stats = Achievement.stats_for_user(@synced_achievements, Achievement.professions)
    @pets_stats = Achievement.stats_for_user(@synced_achievements, Achievement.pets)
    @collections_stats = Achievement.stats_for_user(@synced_achievements, Achievement.collections)
    @exploration_stats = Achievement.stats_for_user(@synced_achievements, Achievement.exploration)
    @events_stats = Achievement.stats_for_user(@synced_achievements, Achievement.events)
  end

  def load_expansion_achievements
    # Récupérer toutes les catégories avec leurs stats
    achievements_scope = @selected_expansion.achievements.normal

    # Si une catégorie est sélectionnée
    if @selected_category.present?
      achievements_scope = achievements_scope.where(category: @selected_category)
    end

    # Filtrer par completed/incomplete
    if @show_completed
      @achievements = achievements_scope.ordered_by_name
    else
      @achievements = achievements_scope.where.not(blizzard_id: @synced_achievements).ordered_by_name
    end

    # Stats pour la sélection actuelle
    @current_stats = Achievement.stats_for_user(@synced_achievements, achievements_scope)

    # Grouper par catégorie pour affichage
    @categories_with_stats = @selected_expansion.achievements.normal
                                                .where.not(category: nil)
                                                .grouped_by_category_with_stats(@synced_achievements)
  end

  def load_special_category_achievements(base_scope, title)
    @category_title = title

    # Catégories disponibles dans ce scope
    achievements_scope = base_scope

    if @selected_category.present?
      achievements_scope = achievements_scope.where(category: @selected_category)
    end

    # Filtrer
    if @show_completed
      @achievements = achievements_scope.ordered_by_name
    else
      @achievements = achievements_scope.where.not(blizzard_id: @synced_achievements).ordered_by_name
    end

    @current_stats = Achievement.stats_for_user(@synced_achievements, achievements_scope)

    # Catégories avec stats
    @categories_with_stats = base_scope.where.not(category: nil)
                                      .grouped_by_category_with_stats(@synced_achievements)
  end

  def extract_completed_achievement_ids(api_data)
    completed_ids = []
    return completed_ids unless api_data['achievements']

    api_data['achievements'].each do |achievement_data|
      completed_ids << achievement_data['id'] if achievement_data['id']

      if achievement_data['achievements']
        achievement_data['achievements'].each do |sub_ach|
          completed_ids << sub_ach['id'] if sub_ach['id']
        end
      end
    end

    completed_ids.uniq
  end
end
