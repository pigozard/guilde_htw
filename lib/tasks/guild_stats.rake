namespace :guild do
  desc "Update guild statistics from APIs"
  task update_stats: :environment do
    puts "🔄 Mise à jour des stats de guilde..."
    UpdateGuildStatisticsJob.perform_now
    puts "✅ Stats mises à jour !"
  end
end
