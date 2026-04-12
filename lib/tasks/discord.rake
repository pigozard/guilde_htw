namespace :discord do
  desc "Envoie les rappels Discord pour les events dans 3 jours"
  task event_reminders: :environment do
    DiscordEventReminderJob.perform_now
  end
end
