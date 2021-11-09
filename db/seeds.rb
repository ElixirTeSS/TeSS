# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).

# Roles
puts "\nSeeding roles"
Role.create_roles

# Default user
puts "\nSeeding default user"
User.get_default_user

# Nodes
puts "\nSeeding nodes"
path = File.join(Rails.root, 'config', 'data', 'elixir_nodes.json')
hash = JSON.parse(File.read(path))
Node.load_from_hash(hash, verbose: false)

# Admin User
puts "\nSeeding admin user"
User.create!(:email=>ENV["ADMIN_EMAIL"],:username=>ENV["ADMIN_USERNAME"],:password=>ENV["ADMIN_PASSWORD"],:role=>Role.find_by_name('admin'),:processing_consent=>1)

puts "Done"
