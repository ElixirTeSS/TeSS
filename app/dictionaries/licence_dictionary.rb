# Dictionary of licences from http://licenses.opendefinition.org/licenses/groups/all.json
# Converted to yaml and saved to config/dictionaries/licences.yml

# Inspired by SEEK's ImageFileDictionary
# https://github.com/seek4science/seek/blob/master/lib/seek/image_file_dictionary.rb
class LicenceDictionary < Dictionary

  DEFAULT_FILE = 'licences.yml'

  def licence_abbreviations
    @abbrvs ||= @dictionary.keys
  end

  def licence_names(licence_dictionary = @dictionary)
    @licence_names ||= licence_dictionary.map { |_, value| value['title'] }
  end

  # Translate a URI or ID in the wrong case to a valid ID, if one exists.
  def normalize_id(id)
    @uri_mapping[id] || @downcase_mapping[id.downcase]
  end

  def grouped_options_for_select(existing = nil)
    existing = Set.new(existing) if existing
    d = if existing
          @dictionary.select { |key, _value| existing.include?(key) }
        else
          @dictionary
        end
    priority = Set.new(TeSS::Config.priority_licences || [])
    groups = { nil => [], 'Common' => [], 'Other' => [] }
    d.each do |key, value|
      opt = if value['description'].nil?
              [value['title'], key, '']
            else
              [value['title'], key, value['description']]
            end

      group = priority.include?(key) ? 'Common' : 'Other'
      group = nil if key == 'notspecified'
      groups[group] << opt
    end
    groups.transform_values { |opts| opts.sort_by { |x| x[0] } }
  end

  private

  def dictionary_filepath
    get_file_path 'licences', DEFAULT_FILE
  end

  # For each license, map all related URIs to its SPDX ID for fast lookups
  def load_dictionary
    d = super
    @uri_mapping = {}
    @downcase_mapping = {}
    d.each do |id, data|
      uris = data['see_also'] || []
      uris << data['reference']
      uris << data['details_url']
      uris.reject(&:blank?).each do |uri|
        @uri_mapping[uri] = id
      end
      @downcase_mapping[id.downcase] = id
    end
    d
  end

end
