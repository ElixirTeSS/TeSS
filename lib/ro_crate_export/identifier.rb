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
  end
end
