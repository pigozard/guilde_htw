require 'httparty'

class BlizzardApiService
  include HTTParty
  base_uri 'https://eu.api.blizzard.com'

  def initialize(region: nil)
    @region = region || ENV['BLIZZARD_REGION'] || 'eu'
    @client_id = ENV['BLIZZARD_CLIENT_ID']
    @client_secret = ENV['BLIZZARD_CLIENT_SECRET']
    @access_token = nil
    @namespace = "static-#{@region}"
    @profile_namespace = "profile-#{@region}"
  end

  # Récupère un token d'accès OAuth2
  def authenticate
    response = HTTParty.post(
      "https://#{@region}.battle.net/oauth/token",
      body: { grant_type: 'client_credentials' },
      basic_auth: { username: @client_id, password: @client_secret }
    )

    if response.success?
      @access_token = response['access_token']
      Rails.logger.info "✅ Authentification réussie pour région #{@region}"
      true
    else
      Rails.logger.error "❌ Erreur d'authentification : #{response.code}"
      false
    end
  end

  # Récupère un item par son ID
  def get_item(item_id, locale: 'fr_FR')
    return nil unless @access_token

    response = self.class.get(
      "/data/wow/item/#{item_id}",
      query: {
        namespace: @namespace,
        locale: locale
      },
      headers: {
        'Authorization' => "Bearer #{@access_token}"
      }
    )

    if response.success?
      response.parsed_response
    else
      Rails.logger.error "❌ Erreur #{response.code} pour item #{item_id}"
      nil
    end
  end

  # Récupère les détails média d'un item (icône)
  def get_item_media(item_id)
    return nil unless @access_token

    response = self.class.get(
      "/data/wow/media/item/#{item_id}",
      query: {
        namespace: @namespace
      },
      headers: {
        'Authorization' => "Bearer #{@access_token}"
      }
    )

    response.success? ? response.parsed_response : nil
  end

  # Recherche d'items
  def search_items(query_params = {}, locale: 'fr_FR')
    return nil unless @access_token

    default_params = {
      namespace: @namespace,
      locale: locale,
      orderby: 'id',
      _page: 1
    }

    response = self.class.get(
      "/data/wow/search/item",
      query: default_params.merge(query_params),
      headers: {
        'Authorization' => "Bearer #{@access_token}"
      }
    )

    response.success? ? response.parsed_response : nil
  end

  # === NOUVEAUX ENDPOINTS POUR LES ACHIEVEMENTS ===

  # Récupère tous les achievements d'un personnage
  def get_character_achievements(realm, character_name, locale: 'fr_FR')
    return nil unless @access_token

    realm_slug = realm.downcase.gsub("'", "").gsub(" ", "-")
    character_slug = character_name.downcase

    response = self.class.get(
      "/profile/wow/character/#{realm_slug}/#{character_slug}/achievements",
      query: {
        namespace: @profile_namespace,
        locale: locale
      },
      headers: {
        'Authorization' => "Bearer #{@access_token}"
      }
    )

    if response.success?
      response.parsed_response
    else
      Rails.logger.error "❌ Erreur #{response.code} pour character #{character_name}-#{realm}"
      Rails.logger.error "Response: #{response.body}"
      nil
    end
  end

  # Récupère les détails d'un achievement spécifique
  def get_achievement(achievement_id, locale: 'fr_FR')
    return nil unless @access_token

    response = self.class.get(
      "/data/wow/achievement/#{achievement_id}",
      query: {
        namespace: @namespace,
        locale: locale
      },
      headers: {
        'Authorization' => "Bearer #{@access_token}"
      }
    )

    response.success? ? response.parsed_response : nil
  end

  # Récupère l'icône d'un achievement
  def get_achievement_media(achievement_id)
    return nil unless @access_token

    response = self.class.get(
      "/data/wow/media/achievement/#{achievement_id}",
      query: {
        namespace: @namespace
      },
      headers: {
        'Authorization' => "Bearer #{@access_token}"
      }
    )

    response.success? ? response.parsed_response : nil
  end

  # Récupère toutes les catégories d'achievements
  def get_achievement_categories(locale: 'fr_FR')
    return nil unless @access_token

    response = self.class.get(
      "/data/wow/achievement-category/index",
      query: {
        namespace: @namespace,
        locale: locale
      },
      headers: {
        'Authorization' => "Bearer #{@access_token}"
      }
    )

    response.success? ? response.parsed_response : nil
  end
  # Récupérer les détails d'une catégorie spécifique
  def get_achievement_category(category_id, locale: 'fr_FR')
    return nil unless @access_token

    response = self.class.get(
      "/data/wow/achievement-category/#{category_id}",
      query: {
        namespace: @namespace,
        locale: locale
      },
      headers: {
        'Authorization' => "Bearer #{@access_token}"
      }
    )

    if response.success?
      response.parsed_response
    else
      Rails.logger.error "❌ Erreur #{response.code} pour catégorie #{category_id}"
      nil
    end
  end
end
