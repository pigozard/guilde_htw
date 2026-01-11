module ApplicationHelper
  def role_icon(role, size: :small)
    return unless role.present?

    css_class = size == :small ? "role-icon-small" : "role-icon"
    image_tag("roles/#{role}.png", alt: role, class: css_class)
  end

  def class_icon(class_name, size: :normal)
    return unless class_name.present?

    filename = class_name.parameterize(separator: '_')
    css_class = size == :small ? "class-image-small" : "class-image"
    image_tag("classes/#{filename}.png", alt: class_name, class: css_class)
  end

  def class_image_path(class_name)
    "classes/#{class_name.to_s.parameterize(separator: '_')}.png"
  end
end
