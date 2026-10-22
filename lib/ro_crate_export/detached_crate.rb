module RoCrateExport
  # Builds a Detached RO-Crate (https://w3id.org/ro/crate/1.3) describing a single TeSS resource.
  # The Root Data Entity is the resource's Bioschemas representation, typed additionally as a Dataset and
  # flattened into an RO-Crate @graph, with the TeSS page URL as its absolute @id.
  class DetachedCrate
    SPEC = 'https://w3id.org/ro/crate/1.3'.freeze
    CONTEXT = "#{SPEC}/context".freeze
    PROFILE = 'https://w3id.org/ro/crate'.freeze
    MEDIA_TYPE = %(application/ld+json; profile="#{PROFILE}").freeze
    METADATA_ID = 'ro-crate-metadata.json'.freeze

    # Bioschemas generator properties that are not defined by the RO-Crate JSON-LD context.
    UNDEFINED_PROPERTIES = %w[contact eligibility event_types hostInstitution].freeze

    NO_LICENCE = 'No licence has been specified for this resource in TeSS.'.freeze

    attr_reader :resource

    def initialize(resource)
      @resource = resource
      @bioschemas = resource.to_bioschemas.first
    end

    def generate
      @entities = {}
      @local_ids = Hash.new(0)
      root = add_entity(root_data_entity)

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

    # The resource's Bioschemas properties, with those required of a Root Data Entity.
    def root_data_entity
      root = @bioschemas.generate.transform_keys(&:to_s).except('@context', 'dct:conformsTo', *UNDEFINED_PROPERTIES)
      root.merge(
        '@type' => ['Dataset', root['@type']],
        'identifier' => Identifier.url(root['identifier']),
        'description' => root['description'].presence || root['name'],
        'datePublished' => date_published,
        'license' => licence(root['license']),
        'conformsTo' => profile,
        'sdPublisher' => publisher
      )
    end

    def date_published
      date = resource.try(:date_published) || resource.created_at || Time.now
      date.iso8601
    end

    def licence(value)
      return NO_LICENCE if value.blank?
      return value unless value.start_with?('http://', 'https://')

      title = LicenceDictionary.instance.lookup_value(resource.licence, 'title')
      { '@id' => value, '@type' => 'CreativeWork', 'name' => title || value }
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
