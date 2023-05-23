# frozen_string_literal: true

# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).

# Roles
Rails.logger.debug "\nSeeding roles"
Role.create_roles

# Default user
Rails.logger.debug "\nSeeding default user"
User.get_default_user

# Nodes
Rails.logger.debug "\nSeeding nodes"
path = File.join(Rails.root, 'config', 'data', 'elixir_nodes.json')
hash = JSON.parse(File.read(path))
Node.load_from_hash(hash, verbose: false)

# Admin User
if ENV['ADMIN_USERNAME']
  Rails.logger.debug "\nSeeding admin user"
  u = User.find_or_initialize_by(username: ENV['ADMIN_USERNAME'], role: Role.find_by(name: 'admin'))
  u.update!(email: ENV['ADMIN_EMAIL'], password: ENV['ADMIN_PASSWORD'], processing_consent: '1') unless u.persisted?
end

Rails.logger.debug 'Done'
