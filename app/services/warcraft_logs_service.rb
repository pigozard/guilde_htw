class WarcraftLogsService
  include HTTParty
  base_uri 'https://www.warcraftlogs.com/api/v2'

  DIFFICULTIES = {
    3 => 'Normal',
    4 => 'Héroïque',
    5 => 'Mythique'
  }

  RAID_CONFIGS = {
  "The Voidspire"        => { total: 6, bosses: ["Imperator Averzian", "Vorasius", "Fallen-King Salhadaar", "Vaelgor & Ezzorak", "Lightblinded Vanguard", "Crown of the Cosmos"] },
  "The Dreamrift"        => { total: 1, bosses: ["Chimaerus, the Undreamt God"] },
  "March on Quel'Danas"  => { total: 2, bosses: ["Belo'ren", "L'ura"] }
}.freeze

  # Midnight S1 : zone 46 = VS / DR / MQD
  MIDNIGHT_ZONE_IDS = [46].freeze

  def initialize
    @client_id     = ENV['WARCRAFTLOGS_CLIENT_ID']
    @client_secret = ENV['WARCRAFTLOGS_CLIENT_SECRET']
    @access_token  = get_access_token
  end

  def guild_data
    return mock_data unless @access_token

    guild_name = "Highway to Wipe"
    server     = "eitrigg"
    region     = "EU"

    start_date = 6.months.ago.to_i * 1000
    end_date   = Time.now.to_i * 1000

    guild_query = <<~GRAPHQL
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
              zone { id name }
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

    character_query = <<~GRAPHQL
      {
        characterData {
          character(
            name: "Crowstorm",
            serverSlug: "#{server}",
            serverRegion: "#{region}"
          ) {
            recentReports(limit: 10) {
              data {
                code
                title
                startTime
                zone { id name }
                fights(killType: Kills) {
                  name
                  difficulty
                  kill
                }
              }
            }
          }
        }
      }
    GRAPHQL

    Rails.logger.info "🔍 Recherche WCL: #{guild_name} + Crowstorm"
    Rails.logger.info "🔍 Période: #{Time.at(start_date/1000)} → #{Time.at(end_date/1000)}"

    guild_response     = post_query(guild_query)
    character_response = post_query(character_query)

    guild_reports     = guild_response&.dig('data', 'reportData', 'reports', 'data') || []
    character_reports = character_response&.dig('data', 'characterData', 'character', 'recentReports', 'data') || []

    all_reports = (guild_reports + character_reports).uniq { |r| r['code'] }

    Rails.logger.info "=== #{guild_reports.size} guilde + #{character_reports.size} Crowstorm = #{all_reports.size} total ==="

    all_reports.first(10).each do |r|
      date = Time.at(r['startTime'] / 1000) rescue 'date inconnue'
      Rails.logger.info "📊 Zone ID: #{r.dig('zone', 'id')} | #{r.dig('zone', 'name')} | #{r['fights']&.size || 0} kills | #{date}"
    end

    return mock_data if all_reports.empty?

    progression  = calculate_progression(all_reports)
    recent_kills = extract_recent_kills(all_reports)
    death_stats  = guild_death_stats

    Rails.logger.info "✅ #{recent_kills.size} kills trouvés"

    {
      progression:        progression,
      recent_kills:       recent_kills.first(5),
      death_stats:        death_stats,
      latest_report_code: all_reports.first&.dig('code')
    }
  rescue => e
    Rails.logger.error "❌ Exception: #{e.message}"
    Rails.logger.error e.backtrace.first(5).join("\n")
    mock_data
  end

  def guild_death_stats
  return mock_death_stats unless @access_token

  start_date = 1.month.ago.to_i * 1000
  end_date   = Time.now.to_i * 1000

  # Récupère les reports récents de la guilde + Crowstorm
  guild_query = <<~GRAPHQL
    {
      reportData {
        reports(
          guildName: "Highway to Wipe",
          guildServerSlug: "eitrigg",
          guildServerRegion: "EU",
          startTime: #{start_date},
          endTime: #{end_date},
          limit: 10
        ) {
          data {
            code
            zone { id }
          }
        }
      }
    }
  GRAPHQL

  character_query = <<~GRAPHQL
    {
      characterData {
        character(
          name: "Crowstorm",
          serverSlug: "eitrigg",
          serverRegion: "EU"
        ) {
          recentReports(limit: 5) {
            data {
              code
              zone { id }
            }
          }
        }
      }
    }
  GRAPHQL

  guild_response     = post_query(guild_query)
  character_response = post_query(character_query)

  guild_reports     = guild_response&.dig('data', 'reportData', 'reports', 'data') || []
  character_reports = character_response&.dig('data', 'characterData', 'character', 'recentReports', 'data') || []

  all_reports = (guild_reports + character_reports)
    .uniq { |r| r['code'] }
    .select { |r| MIDNIGHT_ZONE_IDS.include?(r.dig('zone', 'id')) }

  return mock_death_stats if all_reports.empty?

  player_deaths  = Hash.new(0)
  player_classes = {}

  all_reports.first(5).each do |report|
    code = report['code']
    next unless code

    death_query = <<~GRAPHQL
      {
        reportData {
          report(code: "#{code}") {
            masterData {
              actors(type: "Player") {
                id
                name
                subType
              }
            }
            events(dataType: Deaths, startTime: 0, endTime: 99999999999) {
              data
            }
          }
        }
      }
    GRAPHQL

    response = post_query(death_query)
    next unless response

    actors = response.dig('data', 'reportData', 'report', 'masterData', 'actors') || []
    actors_map = actors.each_with_object({}) do |a, map|
      map[a['id']] = { name: a['name'], class: a['subType'] }
    end

    events = response.dig('data', 'reportData', 'report', 'events', 'data') || []

    events.each do |event|
      actor = actors_map[event['targetID']]
      next unless actor

      name  = actor[:name]
      klass = actor[:class]

      player_deaths[name]  += 1
      player_classes[name] ||= klass
    end
  end

  return mock_death_stats if player_deaths.empty?

  player_deaths
    .sort_by { |_, d| -d }
    .first(10)
    .map { |name, deaths| { player: name, deaths: deaths, class: player_classes[name] || 'Unknown' } }
  rescue => e
  Rails.logger.error "guild_death_stats error: #{e.message}"
  mock_death_stats
  end

  private

  def post_query(query)
    response = self.class.post(
      '/client',
      headers: {
        'Authorization' => "Bearer #{@access_token}",
        'Content-Type'  => 'application/json'
      },
      body: { query: query }.to_json
    )

    unless response.success?
      Rails.logger.error "❌ WCL HTTP #{response.code}"
      return nil
    end

    parsed = response.parsed_response
    if parsed['errors']
      Rails.logger.error "❌ WCL GraphQL errors: #{parsed['errors']}"
      return nil
    end

    parsed
  end

  def get_access_token
    return nil unless @client_id && @client_secret

    response = self.class.post(
      'https://www.warcraftlogs.com/oauth/token',
      body: {
        grant_type:    'client_credentials',
        client_id:     @client_id,
        client_secret: @client_secret
      }
    )

    if response.success?
      Rails.logger.info "✅ Warcraft Logs: Token obtenu"
      response['access_token']
    else
      Rails.logger.error "❌ Warcraft Logs Auth Error: #{response.code}"
      nil
    end
  rescue => e
    Rails.logger.error "❌ Warcraft Logs Auth Error: #{e.message}"
    nil
  end

  def calculate_progression(reports)
    raids_kills = RAID_CONFIGS.transform_values { { 3 => Set.new, 4 => Set.new, 5 => Set.new } }

    reports.each do |report|
      zone_id = report.dig('zone', 'id')
      next unless MIDNIGHT_ZONE_IDS.include?(zone_id)

      (report['fights'] || []).each do |fight|
        next unless fight['kill']

        boss_name  = fight['name']
        difficulty = fight['difficulty']
        raid_name = RAID_CONFIGS.find { |_, v| v[:bosses].any? { |b| boss_name.include?(b) } }&.first
        next unless raid_name

        raids_kills[raid_name][difficulty]&.add(boss_name)
      end
    end

    RAID_CONFIGS.each_with_object({}) do |(raid_name, config), result|
      result[raid_name] = {
        total:  config[:total],
        normal: { killed: raids_kills[raid_name][3].size, total: config[:total] },
        heroic: { killed: raids_kills[raid_name][4].size, total: config[:total] },
        mythic: { killed: raids_kills[raid_name][5].size, total: config[:total] }
      }
    end
  end

  def extract_recent_kills(reports)
    kills = []

    reports.each do |report|
    zone_id = report.dig('zone', 'id')
    next unless MIDNIGHT_ZONE_IDS.include?(zone_id)

    fights = report['fights'] || []
    total = fights.size

    fights.each_with_index do |fight, index|
      next unless fight['kill']

      kills << {
        boss:       fight['name'],
        difficulty: DIFFICULTIES[fight['difficulty']] || 'Inconnu',
        date:       Time.at(report['startTime'] / 1000),
        order:      index  # position dans le report = ordre chronologique
      }
    end
  end
    # Tri : d'abord par date décroissante, puis par ordre décroissant dans le report
  kills.sort_by { |k| [-k[:date].to_i, -k[:order]] }.first(5)
  end

  def parse_death_stats(response)
    data    = response.parsed_response
    reports = data.dig('data', 'reportData', 'reports', 'data') || []

    player_deaths  = Hash.new(0)
    player_classes = {}

    reports.each do |report|
      zone_id = report.dig('zone', 'id')
      next unless MIDNIGHT_ZONE_IDS.include?(zone_id)

      (report['rankings'] || []).each do |ranking|
        name   = ranking['name']
        deaths = ranking['deaths'] || 0
        klass  = ranking['class']

        player_deaths[name]  += deaths
        player_classes[name] ||= klass
      end
    end

    return [] if player_deaths.empty?

    player_deaths
      .sort_by { |_, d| -d }
      .first(10)
      .map { |name, deaths| { player: name, deaths: deaths, class: player_classes[name] || 'Unknown' } }
  rescue => e
    Rails.logger.error "Parse death stats error: #{e.message}"
    []
  end

  def mock_death_stats
    [
      { player: "Inboxfear",   deaths: 42, class: "Paladin" },
      { player: "Healystic",   deaths: 38, class: "Priest" },
      { player: "Shadowblade", deaths: 35, class: "Rogue" },
      { player: "Pyromancer",  deaths: 31, class: "Mage" },
      { player: "Tankmaster",  deaths: 28, class: "Warrior" }
    ]
  end

  def mock_data
    Rails.logger.warn "⚠️ Utilisation des données mock"
    {
      progression: {
        "The Voidspire"       => { total: 6, normal: { killed: 6, total: 6 }, heroic: { killed: 4, total: 6 }, mythic: { killed: 1, total: 6 } },
        "The Dreamrift"       => { total: 1, normal: { killed: 1, total: 1 }, heroic: { killed: 1, total: 1 }, mythic: { killed: 0, total: 1 } },
        "March on Quel'Danas" => { total: 2, normal: { killed: 0, total: 2 }, heroic: { killed: 0, total: 2 }, mythic: { killed: 0, total: 2 } }
      },
      recent_kills: [
        { boss: "Alleria Windrunner",    difficulty: "Héroïque", date: 1.day.ago },
        { boss: "Lightblinded Vanguard", difficulty: "Héroïque", date: 1.day.ago },
        { boss: "Chimaerus",             difficulty: "Héroïque", date: 2.days.ago }
      ],
      death_stats: mock_death_stats,
      latest_report_code: nil
    }
  end
end
