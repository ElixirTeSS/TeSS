require 'ingestors/ingestor'

class IngestorMaterial < Ingestor

  @materials = Array.new

  def initialize
    super
    @materials = []
  end

  def add_material (material)
    @materials << material if !material.nil?
  end

  def write (user, provider)
    unless @materials.nil? or @materials.empty?
      # process each material
      @materials.each do |material|
        @processed += 1

        # check for matched materials
        matched_materials = Material.where(title: material.title,
                                           url: material.url,
                                           content_provider: provider)

        if matched_materials.nil? or matched_materials.first.nil?
          # set ingestion parameters and save new event
          material.user = user
          material.content_provider = provider
          material = set_field_defaults material
          material.last_scraped = DateTime.now
          material.scraper_record = true
          save_valid_material material, false
        else
          # update and save matched material
          matched = overwrite_fields matched_materials.first, material
          matched = set_field_defaults matched
          matched.last_scraped = DateTime.now
          matched.scraper_record = true
          save_valid_material matched, true
        end
      end
    end

    # finished
    @messages << "materials processed[#{@processed}] added[#{@added}] updated[#{@updated}] rejected[#{@rejected}]"
    return
  end

  private

  def save_valid_material(resource, matched)
    if resource.valid?
      resource.save!
      matched ? @updated += 1 : @added += 1
    else
      @rejected += 1
      @messages << "Material failed validation: #{resource.title}"
      resource.errors.full_messages.each do |m|
        @messages << "Error: #{m}"
      end
    end
  end

  def set_field_defaults(material)
    # contact
    if material.contact.nil? or material.contact.blank?
      material.contact = material.content_provider.contact
    end
    return material
  end

  def overwrite_fields (old_material, new_material)
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
    return old_material
  end

end
