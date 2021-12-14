class TessDevise::InvitationsController < Devise::InvitationsController

  def new
    if current_user.is_admin? or current_user.is_curator?
      super
    else
      redirect_to root_path
    end
  end

end