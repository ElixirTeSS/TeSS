RailsAdmin.config do |config|
  config.main_app_name = ['TeSS', 'Administration']

  config.authenticate_with do
    redirect_to main_app.root_path unless current_user.try(:is_admin?)
    warden.authenticate! scope: :user
  end

  config.current_user_method(&:current_user)
end