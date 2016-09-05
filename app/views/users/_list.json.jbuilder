json.array!(users) do |user|
  json.extract! user, :id, :username
  json.extract! user.profile, :firstname, :surname if user.profile
  json.url user_url(user, format: :json)
end
