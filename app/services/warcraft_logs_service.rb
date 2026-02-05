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

    # Query pour récupérer les reports et les stats
    query = <<~GRAPHQL
      {
        reportData {
          reports(guildName: "#{guild_name}", guildServerSlug: "#{server}", guildServerRegion: "#{region}", limit: 20) {
            data {
              title
              startTime
              endTime
              zone {
                id
                name
              }
              fights {
                id
                name
                difficulty
                kill
                bossPercentage
              }
              rankings(playerMetric: deaths)
            }
          }
        }
      }
    GRAPHQL

    response = self.class.post(
      '/client',
      headers: {
        'Authorization' => "Bearer #{@access_token}",
        'Content-Type' => 'application/json'
      },
      body: { query: query }.to_json
    )

    if response.success?
      parse_complete_data(response)
    else
      Rails.logger.error "WarcraftLogs API Error: #{response.code} - #{response.body}"
      mock_data
    end
  rescue => e
    Rails.logger.error "WarcraftLogs API Error: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
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
    reports = data.dig('data', 'reportData', 'reports', 'data') || []

    if reports.empty?
      Rails.logger.warn "⚠️ Aucun report trouvé"
      return mock_data
    end

    # Progression par difficulté
    progression = calculate_progression(reports)

    # Kills récents (tous)
    recent_kills = extract_recent_kills(reports)

    # Deaths (Wall of Shame)
    death_stats = calculate_deaths(reports)

    {
      progression: progression,
      recent_kills: recent_kills.first(5),
      death_stats: death_stats.first(5)
    }
  end

  def calculate_progression(reports)
    # Compter les boss uniques tués par difficulté
    kills_by_difficulty = {
      3 => Set.new,  # Normal
      4 => Set.new,  # Héroïque
      5 => Set.new   # Mythique
    }

    reports.each do |report|
      next unless report.dig('zone', 'id') == 38  # Nerub-ar Palace

      fights = report['fights'] || []

      fights.each do |fight|
        next unless fight['kill']

        difficulty = fight['difficulty']
        boss_name = fight['name']

        kills_by_difficulty[difficulty]&.add(boss_name) if kills_by_difficulty[difficulty]
      end
    end

    {
      normal: {
        killed: kills_by_difficulty[3].size,
        total: 8
      },
      heroic: {
        killed: kills_by_difficulty[4].size,
        total: 8
      },
      mythic: {
        killed: kills_by_difficulty[5].size,
        total: 8
      },
      raid_name: "Nerub-ar Palace"
    }
  end

  def extract_recent_kills(reports)
    kills = []

    reports.each do |report|
      next unless report.dig('zone', 'id') == 38

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

  def calculate_deaths(reports)
    # Compteur de morts par joueur
    deaths_by_player = Hash.new(0)

    reports.each do |report|
      rankings = report['rankings']
      # Note: Cette partie nécessite plus d'investigation de l'API
      # Pour l'instant, on retourne des données mock
    end

    # Mock data pour les deaths (à remplacer quand on aura la vraie query)
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
        raid_name: "Nerub-ar Palace"
      },
      recent_kills: [
        { boss: "Ulgrax", difficulty: "Mythique", date: 1.day.ago },
        { boss: "Bloodbound", difficulty: "Mythique", date: 2.days.ago },
        { boss: "Sikran", difficulty: "Mythique", date: 3.days.ago }
      ],
      death_stats: [
        { player: "Inboxfear", deaths: 42, class: "Paladin" },
        { player: "Healystic", deaths: 38, class: "Priest" }
      ]
    }
  end
end
