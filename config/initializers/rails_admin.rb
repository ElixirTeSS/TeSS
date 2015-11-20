RailsAdmin.config do |config|

  config.authenticate_with do
    redirect_to main_app.root_path unless current_user.try(:is_admin?)
    warden.authenticate! scope: :user
  end
  config.current_user_method(&:current_user)

  config.audit_with :paper_trail, 'User', 'PaperTrail::Version'
end