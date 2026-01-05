module CharactersHelper
  def role_badge(role)
    case role
    when "tank"
      content_tag(:span, "🛡️ Tank", class: "badge bg-danger")
    when "healer"
      content_tag(:span, "💚 Heal", class: "badge bg-success")
    when "dps"
      content_tag(:span, "⚔️ DPS", class: "badge bg-primary")
    end
  end

  def class_icon(class_name)
    # Transforme "Demon Hunter" en "demon_hunter"
    filename = class_name.parameterize(separator: '_')
    image_tag("classes/#{filename}.png", alt: class_name, class: "class-image")
  end
end
