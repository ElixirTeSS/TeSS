module Ingestors
  module MaterialIngestion
    def add_material(material)
      @materials << material unless material.nil?
    end

    def write_materials(user, provider)
      unless @materials.nil? or @materials.empty?
        # process each material
        @materials.each do |material|
          @stats[:materials][:processed] += 1

          # check for matched events
          material.user ||= user
          material.content_provider ||= provider
          existing_material = Material.check_exists(material)

          update = false
          if existing_material && existing_material.content_provider == provider
            update = true
            material = overwrite_material_fields(existing_material, material)
          end

          material = set_resource_defaults(material)
          save_valid_material(material, update)
        end
      end

      # finished
      nil
    end

    private

    def save_valid_material(resource, matched)
      if resource.valid?
        resource.save!
        @stats[:materials][matched ? :updated : :added] += 1
      else
        @stats[:materials][:rejected] += 1
        @messages << "Material failed validation: #{resource.title}"
        resource.errors.full_messages.each do |m|
          @messages << "Error: #{m}"
        end
      end
    end

    def overwrite_material_fields(old_material, new_material)
      # overwrite unlocked attributes
      locked_fields = old_material.locked_fields

      (new_material.changed - ['content_provider_id', 'user_id']).each do |attr|
        old_material.send("#{attr}=", new_material.send(attr)) unless locked_fields.include?(attr)
      end

      old_material
    end
  end
end
