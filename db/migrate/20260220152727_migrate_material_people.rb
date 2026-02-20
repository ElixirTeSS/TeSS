class MigrateMaterialPeople < ActiveRecord::Migration[7.2]
  unless defined?(Person)
    class Person < ActiveRecord::Base
      def self.attr_from_string(person_string)
        orcid = nil
        name = person_string.gsub(/\s*\(?(orcid: )?(https?:\/\/orcid\.org\/)?(\d\d\d\d-\d\d\d\d-\d\d\d\d-\d\d\d[\dxX])[ \)]*/) do |_|
          orcid = $3
          ''
        end.strip
        { full_name: name, orcid: orcid }
      end
    end
  end

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
    # Restore arrays from Person model - Unused because the data is still intact at this point.
    # Material.find_each do |material|
    #   people_to_array(material, 'authors', 'author')
    #   people_to_array(material, 'contributors', 'contributor')
    # end
  end

  private

  def array_to_people(resource, column_name, role)
    return unless resource.respond_to?(:read_attribute)
    # Get the raw array from database
    people_array = resource.read_attribute(column_name)
    return if people_array.blank?

    people_array.each do |person_name|
      next if person_name.blank?

      attr = Person.attr_from_string(person_name).merge(resource: resource, role: role)
      Person.find_or_create_by!(attr)
    end
  end

  def people_to_array(resource, column_name, role)
    arr = Person.where(resource: resource, role: role).map do |person|
      name = person.display_name
      name += "(#{person.orcid})" if person.orcid
      name
    end

    resource.update_column(column_name, arr)
  end
end

