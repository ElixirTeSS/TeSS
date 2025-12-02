class MigrateMaterialAuthorsData < ActiveRecord::Migration[7.2]
  def up
    # Migrate existing authors from array to Person model
    Material.find_each do |material|
      next if material.authors.blank?

      material.authors.each do |author_name|
        next if author_name.blank?

        # Parse the name - assume "First Last" format
        # Handle edge cases: single names, multiple spaces, etc.
        parts = author_name.strip.split(/\s+/, 2)
        
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
          role: 'author'
        )
      end
    end
  end

  def down
    # Restore authors array from Person model
    Material.find_each do |material|
      author_names = material.people.where(person_links: { role: 'author' }).map(&:full_name).compact
      # Use raw SQL to avoid validation issues
      Material.connection.execute(
        "UPDATE materials SET authors = ARRAY[#{author_names.map { |n| "'#{n.gsub("'", "''")}'" }.join(',')}]::varchar[] WHERE id = #{material.id}"
      )
    end

    # Clean up the new tables
    PersonLink.delete_all
    Person.delete_all
  end
end
