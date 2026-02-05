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
