require 'httparty'

class BlizzardApiService
  include HTTParty
  base_uri 'https://eu.api.blizzard.com'

  def initialize
    @region = ENV['BLIZZARD_REGION'] || 'eu'
    @client_id = ENV['BLIZZARD_CLIENT_ID']
    @client_secret = ENV['BLIZZARD_CLIENT_SECRET']
    @access_token = nil
    @namespace = 'static-eu'  # Namespace générique
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
      puts "✅ Authentification réussie !"
      true
    else
      puts "❌ Erreur d'authentification : #{response.code}"
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
      puts "❌ Erreur #{response.code} pour item #{item_id}"
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
end
