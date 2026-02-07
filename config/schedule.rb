# Use this file to easily define all of your cron jobs.
set :output, "log/cron.log"

# Mise à jour toutes les heures
every 1.hour do
  runner "UpdateGuildStatisticsJob.perform_now"
end
