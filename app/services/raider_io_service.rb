class RaiderIoService
  include HTTParty
  base_uri 'https://raider.io/api/v1'

  def initialize
    @guild_name = "Highway to Wipe"
    @guild_realm = "eitrigg"
    @region = "eu"
  end

  def top_mythic_plus_players
    # Récupérer les membres avec le realm de la GUILDE
    response = self.class.get(
      '/guilds/profile',
      query: {
        region: @region,
        realm: @guild_realm,
        name: @guild_name,
        fields: 'members'
      }
    )

    return mock_data unless response.success?

    members = response.dig('members') || []
    Rails.logger.info "✅ Raider.io: #{members.size} membres trouvés"

    # Dédupliquer les membres par nom AVANT les appels API
    unique_members = members.uniq { |m| m.dig('character', 'name') }
    Rails.logger.info "✅ Après déduplication: #{unique_members.size} membres uniques"

    # Pour chaque membre unique, récupérer son score M+
    player_scores = unique_members.map do |member|
      character_name = member.dig('character', 'name')
      character_realm = member.dig('character', 'realm')  # ← LE REALM DU PERSO

      next unless character_name && character_realm

      Rails.logger.info "🔍 Recherche: #{character_name} @ #{character_realm}"

      # Utiliser LE REALM DU PERSONNAGE, pas celui de la guilde
      char_response = self.class.get(
        '/characters/profile',
        query: {
          region: @region,
          realm: character_realm,  # ← ICI !
          name: character_name,
          fields: 'mythic_plus_scores_by_season:current'
        }
      )

      if char_response.success?
        score = char_response.dig('mythic_plus_scores_by_season', 0, 'scores', 'all') || 0

        Rails.logger.info "📊 #{character_name}-#{character_realm}: #{score}"

        {
          name: character_name,
          score: score.round,
          class: char_response['class'],
          spec: char_response['active_spec_name']
        }
      else
        Rails.logger.warn "⚠️  Échec pour #{character_name}-#{character_realm}"
        nil
      end
    end.compact

    # Trier par score décroissant et garder le top 10
    top_players = player_scores.sort_by { |p| -p[:score] }.first(10)

    Rails.logger.info "✅ Raider.io: Top 10 calculé"
    top_players.each_with_index do |player, i|
      Rails.logger.info "  #{i+1}. #{player[:name]} - #{player[:score]}"
    end

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
      { name: "Moonfury", score: 2987, class: "Druid", spec: "Balance" },
      { name: "Frostbite", score: 2921, class: "Death Knight", spec: "Frost" },
      { name: "Stormcaller", score: 2856, class: "Shaman", spec: "Elemental" },
      { name: "Nightwhisper", score: 2790, class: "Rogue", spec: "Assassination" },
      { name: "Ironhide", score: 2734, class: "Warrior", spec: "Fury" },
      { name: "Wildheart", score: 2688, class: "Druid", spec: "Feral" }
    ]
  end
end
