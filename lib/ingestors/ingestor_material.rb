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
    processed = 0
    updated = 0
    added = 0
    @materials.each do |material|
      processed += 1

      # check for matched materials
      matched_materials = Material.where(title: material.title, url: material.url, content_provider: provider)

      if matched_materials.nil? or matched_materials.first.nil?
        # set ingestion parameters and save new event
        material.user = user
        material.content_provider = provider
        material.scraper_record = true
        material.last_scraped = DateTime.now
        if valid_material? material
          material.save!
          added += 1
        end

      else
        # update and save matched event
        matched = overwrite_fields matched_materials.first, material
        matched.scraper_record = true
        matched.last_scraped = DateTime.now
        if valid_material? matched
          matched.save!
          updated += 1
        end

      end

    end
    written = added + updated
    Scraper.log self.class.name +
                  ": materials added[#{added}] updated[#{updated}] rejected[#{processed - written}]", 3
    return written
  end

  def overwrite_fields (old_material, new_material)
    # overwrite unlocked attributes
    # [title, url, provider] not changed as they are used for matching
    old_material.description = new_material.description   unless old_material.field_locked? :description
    old_material.keywords = new_material.keywords         unless old_material.field_locked? :keywords
    old_material.contact = new_material.contact           unless old_material.field_locked? :contact
    old_material.licence = new_material.licence           unless old_material.field_locked? :licence
    old_material.status = new_material.status             unless old_material.field_locked? :status
    return old_material
  end

  def valid_material? (material)
    # check event attributes
    return true if material.valid?

    # log error messages
    Scraper.log "Material title[#{material.title}] failed validation.", 4
    material.errors.full_messages.each do |message|
      Scraper.log "Material title[#{material.title}] error: " + message, 5
    end

    return false
  end


end