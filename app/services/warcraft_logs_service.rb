class WarcraftLogsService
  include HTTParty
  base_uri 'https://www.warcraftlogs.com/api/v2'

  DIFFICULTIES = {
    3 => 'Normal',
    4 => 'Héroïque',
    5 => 'Mythique'
  }

  def initialize
    @client_id = ENV['WARCRAFTLOGS_CLIENT_ID']
    @client_secret = ENV['WARCRAFTLOGS_CLIENT_SECRET']
    @access_token = get_access_token
  end

  def guild_data
    return mock_data unless @access_token

    guild_name = "Highway to Wipe"
    server = "eitrigg"
    region = "EU"

    # Période : 6 derniers mois (en millisecondes)
    start_date = 6.months.ago.to_i * 1000
    end_date = Time.now.to_i * 1000

    # Query GraphQL simplifiée pour réduire la complexité
    query = <<~GRAPHQL
      {
        reportData {
          reports(
            guildName: "#{guild_name}",
            guildServerSlug: "#{server}",
            guildServerRegion: "#{region}",
            startTime: #{start_date},
            endTime: #{end_date},
            limit: 50
          ) {
            data {
              code
              title
              startTime
              zone {
                id
                name
              }
              fights(killType: Kills) {
                name
                difficulty
                kill
              }
            }
          }
        }
      }
    GRAPHQL

    Rails.logger.info "🔍 Recherche WCL: #{guild_name} @ #{server}-#{region}"
    Rails.logger.info "🔍 Période: #{Time.at(start_date/1000)} → #{Time.at(end_date/1000)}"

    response = self.class.post(
      '/client',
      headers: {
        'Authorization' => "Bearer #{@access_token}",
        'Content-Type' => 'application/json'
      },
      body: { query: query }.to_json
    )

    Rails.logger.info "=== RESPONSE CODE: #{response.code} ==="

    if response.success?
      parsed = response.parsed_response

      # Vérifier les erreurs de l'API
      if parsed['errors']
        Rails.logger.error "❌ API Errors: #{parsed['errors']}"
        Rails.logger.warn "⚠️ Utilisation des données mock (erreur API)"
        return mock_data
      end

      Rails.logger.info "✅ Réponse API valide, parsing des données..."
      parse_complete_data(response)
    else
      Rails.logger.error "❌ HTTP Error: #{response.code}"
      Rails.logger.warn "⚠️ Utilisation des données mock (erreur HTTP)"
      mock_data
    end
  rescue => e
    Rails.logger.error "❌ Exception: #{e.message}"
    Rails.logger.error e.backtrace.first(5).join("\n")
    Rails.logger.warn "⚠️ Utilisation des données mock (exception)"
    mock_data
  end

  private

  def get_access_token
    return nil unless @client_id && @client_secret

    response = self.class.post(
      'https://www.warcraftlogs.com/oauth/token',
      body: {
        grant_type: 'client_credentials',
        client_id: @client_id,
        client_secret: @client_secret
      }
    )

    if response.success?
      token = response['access_token']
      Rails.logger.info "✅ Warcraft Logs: Token obtenu"
      token
    else
      Rails.logger.error "❌ Warcraft Logs Auth Error: #{response.code}"
      nil
    end
  rescue => e
    Rails.logger.error "❌ Warcraft Logs Auth Error: #{e.message}"
    nil
  end

  def parse_complete_data(response)
    data = response.parsed_response

    # Debug: structure complète
    Rails.logger.info "=== STRUCTURE RÉPONSE: #{data.keys} ==="

    reports = data.dig('data', 'reportData', 'reports', 'data') || []

    Rails.logger.info "=== NOMBRE DE REPORTS TROUVÉS: #{reports.size} ==="

    # 🔍 DEBUG - Afficher les Zone IDs
    if reports.any?
      reports.first(10).each do |report|
        date = Time.at(report['startTime'] / 1000) rescue 'date inconnue'
        zone_id = report.dig('zone', 'id')
        zone_name = report.dig('zone', 'name')
        fights_count = report['fights']&.size || 0
        Rails.logger.info "📊 Zone ID: #{zone_id} | Zone Name: '#{zone_name}' | Fights: #{fights_count} | Date: #{date}"
      end
    else
      Rails.logger.warn "⚠️ Aucun report trouvé - Vérifiez que la guilde a uploadé des logs"
    end

    Rails.logger.info "================================"

    if reports.empty?
      Rails.logger.warn "⚠️ Utilisation des données mock"
      return mock_data
    end

    # Progression par difficulté
    progression = calculate_progression(reports)

    # Kills récents
    recent_kills = extract_recent_kills(reports)

    # Deaths (mock pour l'instant)
    death_stats = mock_death_stats

    Rails.logger.info "✅ Progression #{progression[:raid_name]}: N#{progression[:normal][:killed]}/#{progression[:normal][:total]} H#{progression[:heroic][:killed]}/#{progression[:heroic][:total]} M#{progression[:mythic][:killed]}/#{progression[:mythic][:total]}"
    Rails.logger.info "✅ #{recent_kills.size} kills trouvés"

    {
      progression: progression,
      recent_kills: recent_kills.first(5),
      death_stats: death_stats
    }
  end

  def calculate_progression(reports)
    # Compter les boss uniques tués par difficulté
    kills_by_difficulty = {
      3 => Set.new,  # Normal
      4 => Set.new,  # Héroïque
      5 => Set.new   # Mythique
    }

    # Suivre le dernier raid avec des kills
    last_raid_name = "Aucun raid"
    last_raid_date = nil

    reports.each do |report|
      zone_id = report.dig('zone', 'id')
      zone_name = report.dig('zone', 'name')

      # Raids TWW: Manaforge Omega (44), Liberation of Undermine (39), Nerub-ar Palace (38)
      # On va logger tous les IDs pour trouver le bon
      next unless [44, 39, 38].include?(zone_id)

      fights = report['fights'] || []
      has_kills = false

      fights.each do |fight|
        next unless fight['kill']

        has_kills = true
        difficulty = fight['difficulty']
        boss_name = fight['name']

        kills_by_difficulty[difficulty]&.add(boss_name) if kills_by_difficulty[difficulty]
      end

      # Mettre à jour le dernier raid si ce report a des kills
      if has_kills
        report_date = report['startTime']
        if last_raid_date.nil? || report_date > last_raid_date
          last_raid_date = report_date
          last_raid_name = zone_name
        end
      end
    end

    # Déterminer le nombre total de boss selon le raid
    total_bosses = case last_raid_name
    when "Manaforge Omega" then 8
    when "Liberation of Undermine" then 8
    when "Nerub-ar Palace" then 8
    else 8
    end

    {
      normal: {
        killed: kills_by_difficulty[3].size,
        total: total_bosses
      },
      heroic: {
        killed: kills_by_difficulty[4].size,
        total: total_bosses
      },
      mythic: {
        killed: kills_by_difficulty[5].size,
        total: total_bosses
      },
      raid_name: last_raid_name
    }
  end

  def extract_recent_kills(reports)
    kills = []

    reports.each do |report|
      zone_id = report.dig('zone', 'id')
      # Raids TWW: Manaforge Omega (44), Liberation of Undermine (39), Nerub-ar Palace (38)
      next unless [44, 39, 38].include?(zone_id)

      fights = report['fights'] || []

      fights.each do |fight|
        next unless fight['kill']

        kills << {
          boss: fight['name'],
          difficulty: DIFFICULTIES[fight['difficulty']] || 'Inconnu',
          date: Time.at(report['startTime'] / 1000)
        }
      end
    end

    # Trier par date (plus récent en premier)
    kills.sort_by { |k| -k[:date].to_i }
  end

  def mock_death_stats
    [
      { player: "Inboxfear", deaths: 42, class: "Paladin" },
      { player: "Healystic", deaths: 38, class: "Priest" },
      { player: "Shadowblade", deaths: 35, class: "Rogue" },
      { player: "Pyromancer", deaths: 31, class: "Mage" },
      { player: "Tankmaster", deaths: 28, class: "Warrior" }
    ]
  end

  def mock_data
    Rails.logger.warn "⚠️ Utilisation des données mock"
    {
      progression: {
        normal: { killed: 8, total: 8 },
        heroic: { killed: 8, total: 8 },
        mythic: { killed: 3, total: 8 },
        raid_name: "Manaforge Omega"
      },
      recent_kills: [
        { boss: "Ulgrax", difficulty: "Mythique", date: 1.day.ago },
        { boss: "Bloodbound Horror", difficulty: "Mythique", date: 2.days.ago },
        { boss: "Sikran", difficulty: "Mythique", date: 3.days.ago }
      ],
      death_stats: mock_death_stats
    }
  end
end
