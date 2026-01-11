module EventsHelper
  def role_icon(role)
    case role
    when "tank"
      image_tag("roles/tank.png", class: "role-icon-small")
    when "healer"
      image_tag("roles/healer.png", class: "role-icon-small")
    when "dps_cac"
      image_tag("roles/dps_cac.png", class: "role-icon-small")
    when "dps_caster"
      image_tag("roles/dps_caster.png", class: "role-icon-small")
    else
      ""
    end
  end
end
