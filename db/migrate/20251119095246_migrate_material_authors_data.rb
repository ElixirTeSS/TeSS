class MigrateMaterialAuthorsData < ActiveRecord::Migration[7.2]
  def up
    # Migrate existing authors from array to Person model
    Material.find_each do |material|
      # Migrate authors
      migrate_people_role(material, 'authors', 'author') if material.respond_to?(:read_attribute) && material.read_attribute(:authors).present?

      # Migrate contributors
      migrate_people_role(material, 'contributors', 'contributor') if material.respond_to?(:read_attribute) && material.read_attribute(:contributors).present?
    end
  end

  def down
    # Restore arrays from Person model
    Material.find_each do |material|
      # Restore authors
      author_names = material.people.where(person_links: { role: 'author' }).map(&:full_name).compact
      Material.connection.execute(
        "UPDATE materials SET authors = ARRAY[#{author_names.map { |n| "'#{n.gsub("'", "''")}'" }.join(',')}]::varchar[] WHERE id = #{material.id}"
      )

      # Restore contributors
      contributor_names = material.people.where(person_links: { role: 'contributor' }).map(&:full_name).compact
      Material.connection.execute(
        "UPDATE materials SET contributors = ARRAY[#{contributor_names.map { |n| "'#{n.gsub("'", "''")}'" }.join(',')}]::varchar[] WHERE id = #{material.id}"
      )
    end

    # Clean up the new tables
    PersonLink.delete_all
    Person.delete_all
  end

  private

  def migrate_people_role(material, column_name, role)
    # Get the raw array from database
    people_array = material.read_attribute(column_name)
    return if people_array.blank?

    people_array.each do |person_name|
      next if person_name.blank?

      # Parse the name - assume "First Last" format
      # Handle edge cases: single names, multiple spaces, etc.
      parts = person_name.strip.split(/\s+/, 2)

      if parts.length == 1
        # Single name - use as last name with empty first name
        first_name = ''
        last_name = parts[0]
      else
        first_name = parts[0]
        last_name = parts[1] || ''
      end

      # Find or create person
      person = Person.find_or_create_by!(
        first_name: first_name,
        last_name: last_name
      )

      # Create the association if it doesn't exist
      PersonLink.find_or_create_by!(
        resource: material,
        person_id: person.id,
        role: role
      )
    end
  end
end
