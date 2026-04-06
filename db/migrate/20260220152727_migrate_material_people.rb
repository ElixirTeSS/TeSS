require_relative '../migration_helper'

class MigrateMaterialPeople < ActiveRecord::Migration[7.2]
  include MigrationHelper

  class Person < ActiveRecord::Base; end unless defined?(Person)

  def up
    # Migrate existing authors from array to Person model
    puts "Updating #{Material.count} materials:"
    Material.find_each do |material|
      array_to_people(material, 'authors', 'author')
      array_to_people(material, 'contributors', 'contributor')
      print '.'
    end
    puts
  end

  def down
    # Restore arrays from Person model
    puts "Updating #{Material.count} materials:"
    Material.find_each do |material|
      people_to_array(material, 'authors', 'author')
      people_to_array(material, 'contributors', 'contributor')
      print '.'
    end
    puts
  end
end
