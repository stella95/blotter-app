module ApplicationHelper
  def nav_item_class(path)
    class_names("nav-item", active: current_page?(path))
  end

  def category_tag(category)
    color = category.color.presence || "#7a7a7a"
    style = "background-color: color-mix(in srgb, #{color} 16%, white); color: #{color};"
    content_tag(:span, category.name, class: "tag", style:)
  end

  def money(amount, currency)
    return nil if amount.nil?

    unit = { "EUR" => "€", "USD" => "$" }.fetch(currency, "#{currency} ")
    number_to_currency(amount, unit:, format: "%u%n", delimiter: ",")
  end
end
