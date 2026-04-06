module MigrationHelper
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

      p = Person.find_or_initialize_by(full_name: name, orcid: orcid, resource: resource, role: role)
      p.save!(validate: false) if p.new_record?
    end
  end

  def people_to_array(resource, column_name, role)
    arr = Person.where(resource: resource, role: role).map do |person|
      name = person.full_name
      name += " (#{person.orcid})" if person.orcid
      name
    end

    resource.update_column(column_name, arr)
  end
end
