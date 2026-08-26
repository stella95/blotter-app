module ApplicationHelper
  def nav_item_class(path)
    class_names("nav-item", active: current_page?(path))
  end
end
