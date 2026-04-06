require_relative '../migration_helper'

class MigrateLearningPathPeople < ActiveRecord::Migration[7.2]
  include MigrationHelper

  class Person < ActiveRecord::Base; end unless defined?(Person)

  def up
    # Migrate existing authors from array to Person model
    puts "Updating #{LearningPath.count} learning paths:"
    LearningPath.find_each do |learning_path|
      array_to_people(learning_path, 'authors', 'author')
      array_to_people(learning_path, 'contributors', 'contributor')
      print '.'
    end
    puts
  end

  def down
    # Restore arrays from Person model
    puts "Updating #{LearningPath.count} learning paths:"
    LearningPath.find_each do |learning_path|
      people_to_array(learning_path, 'authors', 'author')
      people_to_array(learning_path, 'contributors', 'contributor')
      print '.'
    end
    puts
  end
end
