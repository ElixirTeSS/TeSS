json.extract! collaboration, :id

json.user do
  json.extract! collaboration.user, :id, :username
  json.extract! collaboration.user.profile, :firstname, :surname if collaboration.user.profile
end
