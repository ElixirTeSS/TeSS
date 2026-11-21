module RoCrateExport
  # Normalizes identifiers for FAIR Signposting and RO-Crate.
  module Identifier
    DOI_RESOLVER = 'https://doi.org/'.freeze
    DOI_PREFIX = %r{\A(?:doi:|https?://(?:dx\.|www\.)?doi\.org/)}i
    DOI = %r{\A10\.\d{4,}(?:\.\d+)*/\S+\z}

    # Returns a DOI (bare, "doi:" or doi.org URL) as an https://doi.org/ URL, any other http(s) URL unchanged,
    # or nil if the value is neither.
    def self.url(value)
      value = value.to_s.strip
      doi = value.sub(DOI_PREFIX, '')
      return "#{DOI_RESOLVER}#{doi}" if doi.match?(DOI)
      return value if value.match?(%r{\Ahttps?://\S+\z}i)

      nil
    end

    SPDX_LICENCES = 'http://spdx.org/licenses/'.freeze
    SPDX_REFERENCE = %r{\Ahttps?://spdx\.org/licenses/(?<id>[^/]+?)(?:\.html|\.json)?\z}i

    # Returns the URL of a TeSS licence (e.g. "CC-BY-4.0"): for SPDX licences the SPDX license URI, e.g.
    # http://spdx.org/licenses/CC-BY-4.0, which matches SPDX's RDF, rather than the HTML page in the licence
    # dictionary; otherwise the dictionary's reference URL, or nil if there is none.
    def self.licence_url(licence)
      return nil if licence.blank?

      reference = LicenceDictionary.instance.lookup_value(licence, 'reference').presence
      spdx = reference&.match(SPDX_REFERENCE)
      return "#{SPDX_LICENCES}#{spdx[:id]}" if spdx

      reference if reference&.match?(%r{\Ahttps?://\S+\z}i)
    end
  end
end
