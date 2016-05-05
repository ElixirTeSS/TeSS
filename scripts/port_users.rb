# This script expects a users.csv file in the format:
# username | email address | full name
# The full name will have to be split to get the firstname/surname used in the
# profile for the current version of tess.
# Run this script with:
# rails runner -e $ENVIRONMENT $PATH_TO_SCRIPT
# Note that I've assumed you'll put users.csv in a particular place.

IO.readlines("#{Rails.root}/scripts/users.csv").each do |line|
  parts = line.split('|').map(&:strip)
  username = parts[0]
  email = parts[1]
  if !parts[2].nil?
    nameparts = parts[2].split(/\s+/).map(&:strip)
    if nameparts.length == 2
      firstname = nameparts[0]
      lastname = nameparts[1]
    elsif nameparts.length == 3
      firstname = nameparts[0]
      lastname = nameparts[2]
    end
  end
  #puts "#{firstname},#{lastname},#{username},#{email}"
  u = User.find_by_username(username)
  if u.nil?
    u = User.new(:username => username, :email => email)
    u.set_default_profile
    u.set_registered_user_role
    u.authentication_token = Devise.friendly_token
    u.password = Devise.friendly_token
    u.profile.firstname = firstname
    u.profile.surname = lastname
    u.save!
  end


end
