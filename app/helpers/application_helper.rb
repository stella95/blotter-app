module ApplicationHelper
  def nav_item_class(path)
    class_names("nav-item", active: current_page?(path))
  end

  def money(amount, currency)
    return nil if amount.nil?

    unit = { "EUR" => "€", "USD" => "$" }.fetch(currency, "#{currency} ")
    number_to_currency(amount, unit:, format: "%u%n", delimiter: ",")
  end
end
