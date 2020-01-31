module ApplicationHelper
  def sortable(column, title = nil)
    title ||= column.titleize
    direction = (sort_column && sort_direction == "asc") ? "desc" : "asc"
    year = (params[:year]) ?  params[:year] : DateTime.now().year
    link_to title, :sort => column, :direction => direction, :year => year
  end
end
