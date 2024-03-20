# frozen_string_literal: true

module TessDevise
  class InvitationsController < Devise::InvitationsController
    def new
      if current_user.is_admin? || current_user.is_curator?
        super
      else
        redirect_to root_path
      end
    end

    def after_invite_path_for(_resource)
      invitees_path
    end
  end
end
