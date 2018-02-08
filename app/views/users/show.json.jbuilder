json.extract! @user, :id, :username, :created_at, :updated_at
json.extract! @user.profile, :firstname, :surname if @user.profile
