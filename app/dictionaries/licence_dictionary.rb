# Dictionary of licences from http://licenses.opendefinition.org/licenses/groups/all.json
# Converted to yaml and saved to config/dictionaries/licences.yml

# Inspired by SEEK's ImageFileDictionary
# https://github.com/seek4science/seek/blob/master/lib/seek/image_file_dictionary.rb
class LicenceDictionary < Dictionary

  DEFAULT_FILE = 'spdx.yml'

  def licence_abbreviations
    @abbrvs ||= @dictionary.keys
  end

  def licence_names(licence_dictionary=@dictionary)
    @licence_names ||= licence_dictionary.map { |_, value| value['title'] }
  end

  def lookup_uri(uri)
    @uri_mapping[uri]
  end

  private

  def dictionary_filepath
    get_file_path 'licences', DEFAULT_FILE
  end

  # For each license, map all related URIs to its SPDX ID for fast lookups
  def load_dictionary
    d = super
    @uri_mapping = {}
    d.each do |id, data|
      uris = data['see_also'] || []
      uris << data['reference']
      uris << data['details_url']
      uris.reject(&:blank?).each do |uri|
        @uri_mapping[uri] = id
      end
    end
    d
  end

end
