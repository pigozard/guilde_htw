class UpdateGuildStatisticsJob < ApplicationJob
  queue_as :default

  def perform
    Rails.logger.info "🔄 Début de la mise à jour des statistiques de guilde..."

    begin
      warcraftlogs = WarcraftLogsService.new
      wcl_data = warcraftlogs.guild_data

      wcl_data_json = {
        'progression'        => wcl_data[:progression].deep_stringify_keys,
        'recent_kills'       => wcl_data[:recent_kills].map(&:deep_stringify_keys),
        'death_stats'        => wcl_data[:death_stats].map(&:deep_stringify_keys),
        'latest_report_code' => wcl_data[:latest_report_code]
      }

      GuildStatistic.update_warcraft_logs(wcl_data_json)
      Rails.logger.info "✅ Warcraft Logs mis à jour"
    rescue => e
      Rails.logger.error "❌ Erreur Warcraft Logs: #{e.message}"
    end

    begin
      raiderio = RaiderIoService.new
      rio_data = raiderio.top_mythic_plus_players.map(&:deep_stringify_keys)
      GuildStatistic.update_raider_io(rio_data)
      Rails.logger.info "✅ Raider.io mis à jour"
    rescue => e
      Rails.logger.error "❌ Erreur Raider.io: #{e.message}"
    end

    Rails.logger.info "✅ Statistiques de guilde mises à jour avec succès"
  end
end
