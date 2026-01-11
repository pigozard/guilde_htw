module EventsHelper
  def role_icon(role)
    case role
    when "tank"
      "🛡️"
    when "healer"
      "💚"
    when "dps_cac"
      "⚔️"
    when "dps_caster"
      "🔮"
    else
      "❓"
    end
  end
end
