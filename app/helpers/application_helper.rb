module ApplicationHelper
  include Pagy::Frontend

  def sortable(column, title = nil)
    title ||= column.titleize
    direction = (sort_column && sort_direction == "asc") ? "desc" : "asc"
    paramsNew = params.permit(:year, :month, :category, :items, :sort, :direction).to_h
    paramsNew["sort"] = column
    paramsNew["direction"] = direction
    link_to title, paramsNew
  end
end
