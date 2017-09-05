class UserRequiredConstraint
  include UserConstraint

  def matches?(request)
    user = current_user(request)
    user.present?
  end
end
