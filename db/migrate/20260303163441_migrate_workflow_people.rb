require_relative '../migration_helper'

class MigrateWorkflowPeople < ActiveRecord::Migration[7.2]
  include MigrationHelper

  class Person < ActiveRecord::Base; end unless defined?(Person)

  def up
    # Migrate existing authors from array to Person model
    puts "Updating #{Workflow.count} workflows:"
    Workflow.find_each do |workflow|
      array_to_people(workflow, 'authors', 'author')
      array_to_people(workflow, 'contributors', 'contributor')
      print '.'
    end
    puts
  end

  def down
    # Restore arrays from Person model
    puts "Updating #{Workflow.count} workflows:"
    Workflow.find_each do |workflow|
      people_to_array(workflow, 'authors', 'author')
      people_to_array(workflow, 'contributors', 'contributor')
      print '.'
    end
    puts
  end
end
