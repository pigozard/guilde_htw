class DiscordEventReminderJob < ApplicationJob
  queue_as :default

  def perform
    # Events qui commencent dans exactement 3 jours
    target_date = Date.today + 3.days

    events = Event.where(
      start_time: target_date.beginning_of_day..target_date.end_of_day
    )

    events.each do |event|
      DiscordNotificationService.send_event_reminder(event)
    end

    Rails.logger.info("[Discord] #{events.count} rappel(s) envoyé(s) pour le #{target_date}")
  end
end
