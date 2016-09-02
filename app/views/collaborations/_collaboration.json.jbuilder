json.extract! collaboration, :id

json.user do
  json.id collaboration.user.id
  json.extract! collaboration.user.profile, :firstname, :surname if collaboration.user.profile
end
