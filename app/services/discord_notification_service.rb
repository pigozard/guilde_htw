class DiscordNotificationService
  def self.send_event_reminder(event)
    webhook_url = ENV["DISCORD_WEBHOOK_URL"]
    return unless webhook_url.present?

    days_left = (event.start_time.to_date - Date.today).to_i

    message = {
      username: "Highway to Wipe Bot",
      avatar_url: "https://ton-site.com/logo.png", # optionnel
      embeds: [
        {
          title: "📅 Rappel — #{event.title}",
          description: "L'événement a lieu **dans #{days_left} jours** !",
          color: 0xFFD700, # or WoW
          fields: [
            { name: "📆 Date", value: event.start_time.strftime("%A %d %B à %Hh%M"), inline: true },
            { name: "📍 Type", value: event.event_type.humanize, inline: true },
            { name: "✍️ Inscription", value: "[S'inscrire sur le site](https://ton-site.com/events/#{event.id})" }
          ],
          footer: { text: "Highway to Wipe • Eitrigg EU" }
        }
      ]
    }

    uri = URI.parse(webhook_url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Post.new(uri.path)
    request["Content-Type"] = "application/json"
    request.body = message.to_json

    response = http.request(request)
    Rails.logger.info("[Discord] Rappel envoyé pour '#{event.title}' — HTTP #{response.code}")
  end
end
