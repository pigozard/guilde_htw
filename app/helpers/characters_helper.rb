module CharactersHelper
  def role_badge(role)
    image_tag("roles/#{role}.png", alt: role, class: "role-icon")
  end

  def class_icon(class_name)
    filename = class_name.parameterize(separator: '_')
    image_tag("classes/#{filename}.png", alt: class_name, class: "class-image")
  end
end
