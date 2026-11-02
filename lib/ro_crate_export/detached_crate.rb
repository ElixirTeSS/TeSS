module RoCrateExport
  # Builds a Detached RO-Crate (https://w3id.org/ro/crate/1.3) describing a single TeSS resource.
  # The Root Data Entity is a Dataset for the TeSS record, with the TeSS page URL as its absolute @id. Its
  # +mainEntity+ is the resource's Bioschemas representation (e.g. a LearningResource or Event), flattened into the
  # RO-Crate @graph with the resource's external URL as its @id. A material is also a part (+hasPart+) of the crate;
  # an event is not a data entity, so it is only the main entity.
  class DetachedCrate
    SPEC = 'https://w3id.org/ro/crate/1.3'.freeze
    CONTEXT = "#{SPEC}/context".freeze
    PROFILE = 'https://w3id.org/ro/crate'.freeze
    MEDIA_TYPE = %(application/ld+json; profile="#{PROFILE}").freeze
    METADATA_ID = 'ro-crate-metadata.json'.freeze

    # Bioschemas generator properties that are not defined by the RO-Crate JSON-LD context.
    UNDEFINED_PROPERTIES = %w[contact eligibility event_types hostInstitution].freeze

    NO_LICENCE = 'No licence has been specified for this resource in TeSS.'.freeze

    # Resources that are data entities of the crate, not only its main entity.
    PART_CLASSES = %w[Material].freeze

    attr_reader :resource

    def initialize(resource)
      @resource = resource
      @bioschemas = resource.to_bioschemas.first
    end

    def generate
      @entities = {}
      @local_ids = Hash.new(0)
      bioschemas = @bioschemas.generate.transform_keys(&:to_s)
      main = main_entity(bioschemas)
      main_ref = add_entity(main)
      root = add_entity(root_data_entity(bioschemas['@id'], main, main_ref))
      # List the Root Data Entity first after the descriptor, for readers that do not look it up by @id
      @entities = { root['@id'] => @entities[root['@id']] }.merge(@entities)

      descriptor = {
        '@id' => METADATA_ID,
        '@type' => 'CreativeWork',
        'about' => root,
        'conformsTo' => { '@id' => SPEC }
      }

      { '@context' => CONTEXT, '@graph' => [descriptor, *@entities.values] }
    end

    def to_json(*_args)
      JSON.pretty_generate(generate)
    end

    private

    # The TeSS record, with the properties required of a Root Data Entity.
    def root_data_entity(page_url, main, main_ref)
      {
        '@id' => page_url,
        '@type' => 'Dataset',
        'name' => main['name'],
        'description' => main['description'],
        'datePublished' => date_published,
        'license' => licence || NO_LICENCE,
        'publisher' => publisher,
        'mainEntity' => main_ref,
        'hasPart' => (main_ref if PART_CLASSES.include?(resource.class.name) && main['@id'].start_with?('http'))
      }
    end

    # The resource's Bioschemas properties, identified by its external URL (or a local identifier if it has none).
    # Its Bioschemas +url+ is a plain string, so it is replaced by the @id.
    def main_entity(bioschemas)
      main = bioschemas.except('@context', 'dct:conformsTo', *UNDEFINED_PROPERTIES)
      url = external_url
      main.merge(
        '@id' => url || local_id(main['@type']),
        'url' => (main['url'] unless url),
        'identifier' => Identifier.url(main['identifier']),
        'description' => main['description'].presence || main['name'],
        'license' => licence || main['license'],
        'conformsTo' => profile,
        'sdPublisher' => publisher
      )
    end

    def external_url
      url = resource.try(:url).to_s.strip
      url if url.match?(%r{\Ahttps?://[^\s/]+\.[^\s/]+(/\S*)?\z}i)
    end

    def date_published
      date = resource.try(:date_published) || resource.created_at || Time.now
      date.iso8601
    end

    def licence
      url = Identifier.licence_url(resource.try(:licence))
      return nil unless url

      title = LicenceDictionary.instance.lookup_value(resource.licence, 'title')
      { '@id' => url, '@type' => 'CreativeWork', 'name' => title || url }
    end

    def profile
      return nil unless @bioschemas.class.bioschemas_profile

      { '@id' => @bioschemas.class.bioschemas_profile, '@type' => 'Profile',
        'name' => "Bioschemas #{@bioschemas.class.type} profile" }
    end

    def publisher
      url = Rails.application.routes.url_helpers.root_url
      { '@id' => url, '@type' => 'Organization', 'name' => TeSS::Config.site['title'], 'url' => url }
    end

    # Add an entity to the graph, replacing nested objects with references to flattened entities.
    def add_entity(entity)
      entity = flatten_properties(entity)
      existing = @entities[entity['@id']]
      @entities[entity['@id']] = existing ? existing.merge(entity) : entity
      { '@id' => entity['@id'] }
    end

    def flatten_properties(entity)
      entity.to_h.transform_keys(&:to_s).each_with_object({}) do |(key, value), flat|
        next if value.blank?

        flat[key] = key.start_with?('@') ? value : flatten_value(value)
      end
    end

    def flatten_value(value)
      case value
      when Array
        values = value.map { |v| flatten_value(v) }.compact
        values.length == 1 ? values.first : values
      when Hash
        nested = value.transform_keys(&:to_s)
        return nested if nested.keys == ['@id']

        nested['@id'] ||= local_id(nested['@type'])
        add_entity(nested)
      else
        value
      end
    end

    def local_id(type)
      name = Array(type).first.to_s.underscore.dasherize.presence || 'entity'
      "##{name}-#{@local_ids[name] += 1}"
    end
  end
end
