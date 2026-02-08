# lib/tasks/warcraft_logs.rake
namespace :warcraft_logs do
  desc "Synchronise les données Warcraft Logs"
  task sync: :environment do
    puts "🔄 Début sync Warcraft Logs..."

    service = WarcraftLogsService.new
    data = service.guild_data

    # Option A : Cache simple (recommandé pour commencer)
    Rails.cache.write('warcraft_logs_data', data, expires_in: 2.hours)

    puts "✅ Sync terminé - #{data[:recent_kills].size} kills trouvés"
    puts "📊 Progression: #{data[:progression][:raid_name]}"
  end
end
