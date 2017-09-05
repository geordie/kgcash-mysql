class NoUserRequiredConstraint
  include UserConstraint

  def matches?(request)
    !current_user(request).present?
  end
end
