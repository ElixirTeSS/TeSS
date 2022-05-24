class TrainerPolicy < ApplicationPolicy

  def index?
    true
  end

  def show?
    # Anyone (not even logged in) can see users' pages, with restrictions in view
    # that owners and admins only can see their authentication token and email
    true
  end

end