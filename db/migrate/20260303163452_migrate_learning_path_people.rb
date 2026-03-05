class MigrateLearningPathPeople < ActiveRecord::Migration[7.2]
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

  private

  def array_to_people(resource, column_name, role)
    return unless resource.respond_to?(:read_attribute)
    # Get the raw array from database
    people_array = resource.read_attribute(column_name)
    return if people_array.blank?

    people_array.each do |person_name|
      next if person_name.blank?
      orcid = nil
      name = person_name.gsub(/\s*\(?(orcid: )?(https?:\/\/orcid\.org\/)?(\d\d\d\d-\d\d\d\d-\d\d\d\d-\d\d\d[\dxX])[ \)]*/) do |_|
        orcid = $3
        ''
      end.strip

      Person.find_or_create_by!(full_name: name, orcid: orcid, resource: resource, role: role)
    end
  end

  def people_to_array(resource, column_name, role)
    arr = Person.where(resource: resource, role: role).map do |person|
      name = person.full_name
      name += "(#{person.orcid})" if person.orcid
      name
    end

    resource.update_column(column_name, arr)
  end
end
