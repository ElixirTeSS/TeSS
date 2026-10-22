# Adds FAIR Signposting (https://signposting.org/FAIR/) links to the show page of a resource, as an HTTP Link header
# and as <link> elements in the HTML head, and serves a Detached RO-Crate of the resource on request.
#
# Including controllers must define +fair_signposting_resource+, returning the resource being shown.
module FairSignposting
  extend ActiveSupport::Concern

  SCHEMA_ORG = 'https://schema.org/'.freeze
  JSON_LD = 'application/ld+json'.freeze

  included do
    helper_method :fair_signposting_links
    after_action :set_fair_signposting_header, only: :show, if: -> { response.successful? }
  end

  # GET /materials/1/ro-crate-metadata.json
  def ro_crate
    resource = fair_signposting_resource
    authorize resource, :show?
    render_ro_crate(resource)
  end

  private

  # Whether the RO-Crate is requested by content negotiation for JSON-LD with the RO-Crate profile, e.g.
  # "Accept: application/ld+json; profile="https://w3id.org/ro/crate"".
  def ro_crate_requested?
    profile = Regexp.escape(RoCrateExport::DetachedCrate::PROFILE)
    request.headers['Accept'].to_s.match?(%r{application/ld\+json\s*;[^,]*profile="?#{profile}(?=["\s,;]|\z)}i)
  end

  def render_ro_crate(resource)
    render plain: RoCrateExport::DetachedCrate.new(resource).to_json,
           content_type: RoCrateExport::DetachedCrate::MEDIA_TYPE
  end

  # An array of [url, { attribute => value }] pairs.
  def fair_signposting_links
    resource = fair_signposting_resource
    return [] unless resource&.persisted?

    @fair_signposting_links ||= described_by_links(resource) + cite_as_links(resource) + author_links(resource) +
                                licence_links(resource) + type_links(resource)
  end

  def described_by_links(resource)
    [
      [polymorphic_url(resource, format: :jsonld),
       { rel: 'describedby', type: JSON_LD, profile: bioschemas_generator(resource).bioschemas_profile }.compact],
      [polymorphic_url([:ro_crate_metadata, resource]),
       { rel: 'describedby', type: JSON_LD, profile: RoCrateExport::DetachedCrate::PROFILE }],
      [polymorphic_url(resource, format: :json_api), { rel: 'describedby', type: 'application/vnd.api+json' }]
    ]
  end

  def cite_as_links(resource)
    doi_url = RoCrateExport::Identifier.url(resource.try(:doi))
    doi_url ? [[doi_url, { rel: 'cite-as' }]] : []
  end

  def author_links(resource)
    Array(resource.try(:authors)).filter_map(&:orcid_url).uniq.map { |orcid| [orcid, { rel: 'author' }] }
  end

  def licence_links(resource)
    licence = resource.try(:licence)
    licence_url = LicenceDictionary.instance.lookup_value(licence, 'reference') if licence.present?
    licence_url.present? ? [[licence_url, { rel: 'license' }]] : []
  end

  def type_links(resource)
    ["#{SCHEMA_ORG}#{bioschemas_generator(resource).type}", "#{SCHEMA_ORG}AboutPage"].map { |t| [t, { rel: 'type' }] }
  end

  def bioschemas_generator(resource)
    resource.to_bioschemas.first.class
  end

  def set_fair_signposting_header
    links = fair_signposting_links
    return if links.empty?

    signposting = links.map do |url, attributes|
      (["<#{url}>"] + attributes.map { |key, value| %(#{key}="#{value}") }).join(' ; ')
    end
    # Keep any existing links, e.g. asset preload hints added by Rails, but after the signposting links: some clients,
    # such as the Signposting Sniffing browser extension, ignore the whole header unless its first link is a signpost.
    existing = response.get_header('Link').presence
    response.set_header('Link', [*signposting, existing && quote_link_values(existing)].compact.join(', '))
  end

  # Rails' asset preload links have unquoted attribute values that are not valid RFC 8288 tokens (e.g. base64
  # integrity hashes ending in "="), and a valueless "nopush" (a hint for the obsolete HTTP/2 server push), which
  # make strict Link header parsers reject the whole header, including the signposting links. Quote the values and
  # drop "nopush".
  def quote_link_values(header)
    header.split(/,\s*(?=<)/).map do |link|
      target, params = link.split(/(?<=>)/, 2)
      params = params.to_s.gsub(/;\s*nopush\s*(?=;|\z)/, '')
      params = params.gsub(/;\s*(?<key>[\w*-]+)=(?<value>[^";,]+?)\s*(?=;|\z)/) do
        %(; #{Regexp.last_match[:key]}="#{Regexp.last_match[:value]}")
      end
      "#{target}#{params}"
    end.join(', ')
  end
end
