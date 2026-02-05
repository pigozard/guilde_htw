class RaiderIoService
  include HTTParty
  base_uri 'https://raider.io/api/v1'

  def initialize
    @guild_name = "Highway to Wipe"
    @realm = "eitrigg"
    @region = "eu"
  end

  def top_mythic_plus_players
    # Récupérer les membres de la guilde
    response = self.class.get(
      '/guilds/profile',
      query: {
        region: @region,
        realm: @realm,
        name: @guild_name,
        fields: 'members'
      }
    )

    return mock_data unless response.success?

    members = response.dig('members') || []

    Rails.logger.info "✅ Raider.io: #{members.size} membres trouvés"

    # Pour chaque membre, récupérer son score M+
    player_scores = members.map do |member|
      character_name = member['character']['name']

      char_response = self.class.get(
        '/characters/profile',
        query: {
          region: @region,
          realm: @realm,
          name: character_name,
          fields: 'mythic_plus_scores_by_season:current'
        }
      )

      if char_response.success?
        score = char_response.dig('mythic_plus_scores_by_season', 0, 'scores', 'all') || 0
        {
          name: character_name,
          score: score.round,
          class: char_response['class'],
          spec: char_response['active_spec_name']
        }
      end
    end.compact

    # Trier par score décroissant et garder le top 5
    top_players = player_scores.sort_by { |p| -p[:score] }.first(5)

    Rails.logger.info "✅ Raider.io: Top 5 calculé (meilleur score: #{top_players.first[:score]})" if top_players.any?

    top_players

  rescue => e
    Rails.logger.error "Raider.io API Error: #{e.message}"
    mock_data
  end

  private

  def mock_data
    Rails.logger.warn "⚠️ Raider.io: Utilisation des données mock"
    [
      { name: "Inboxfear", score: 3245, class: "Paladin", spec: "Protection" },
      { name: "Shadowblade", score: 3180, class: "Rogue", spec: "Subtlety" },
      { name: "Pyromancer", score: 3156, class: "Mage", spec: "Fire" },
      { name: "Healystic", score: 3098, class: "Priest", spec: "Holy" },
      { name: "Moonfury", score: 2987, class: "Druid", spec: "Balance" }
    ]
  end
end
