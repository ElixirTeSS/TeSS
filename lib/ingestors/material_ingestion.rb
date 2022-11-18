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

          # check for matched materials
          matched_materials = Material.where(title: material.title,
                                             url: material.url,
                                             content_provider: provider)

          if matched_materials.nil? or matched_materials.first.nil?
            # set ingestion parameters and save new event
            material.user = user
            material.content_provider = provider
            material = set_material_defaults material
            material.last_scraped = DateTime.now
            material.scraper_record = true
            save_valid_material material, false
          else
            # update and save matched material
            matched = overwrite_material_fields matched_materials.first, material
            matched = set_material_defaults matched
            matched.last_scraped = DateTime.now
            matched.scraper_record = true
            save_valid_material matched, true
          end
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
        @stats[:events][:rejected] += 1
        @messages << "Material failed validation: #{resource.title}"
        resource.errors.full_messages.each do |m|
          @messages << "Error: #{m}"
        end
      end
    end

    def set_material_defaults(material)
      material
    end

    def overwrite_material_fields(old_material, new_material)
      # overwrite unlocked attributes
      # [title, url, provider] not changed as they are used for matching
      old_material.description = new_material.description unless old_material.field_locked? :description
      old_material.keywords = new_material.keywords unless old_material.field_locked? :keywords
      old_material.contact = new_material.contact unless old_material.field_locked? :contact
      old_material.licence = new_material.licence unless old_material.field_locked? :licence
      old_material.status = new_material.status unless old_material.field_locked? :status
      old_material.authors = new_material.authors unless old_material.field_locked? :authors
      old_material.contributors = new_material.contributors unless old_material.field_locked? :contributors
      old_material.doi = new_material.doi unless old_material.field_locked? :doi

      # return
      old_material
    end
  end
end