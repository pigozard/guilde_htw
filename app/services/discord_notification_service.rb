class DiscordNotificationService
  def self.send_event_reminder(event)
    webhook_url = ENV["DISCORD_WEBHOOK_URL"]
    return unless webhook_url.present?

    days_left = (event.start_time.to_date - Date.today).to_i

    payload = {
      username: "Highway to Wipe Bot",
      embeds: [{
        title: "📅 Rappel — #{event.title}",
        description: "L'événement a lieu **dans #{days_left} jours** !",
        color: 0xFFD700,
        fields: [
          { name: "📆 Date", value: event.start_time.strftime("%A %d %B à %Hh%M"), inline: true },
          { name: "📍 Type", value: event.event_type_label, inline: true }
        ],
        footer: { text: "Highway to Wipe • Eitrigg EU" }
      }]
    }

    response = HTTParty.post(webhook_url, body: payload.to_json, headers: { "Content-Type" => "application/json" })
    Rails.logger.info("[Discord] HTTP #{response.code} — #{response.body}")
  rescue => e
    Rails.logger.error("[Discord] Erreur : #{e.message}")
  end
end
