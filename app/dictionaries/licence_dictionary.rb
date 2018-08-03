# Dictionary of licences from http://licenses.opendefinition.org/licenses/groups/all.json
# Converted to yaml and saved to config/dictionaries/licences.yml

# Inspired by SEEK's ImageFileDictionary
# https://github.com/seek4science/seek/blob/master/lib/seek/image_file_dictionary.rb
class LicenceDictionary < Dictionary

  def licence_abbreviations
    @abbrvs ||= @dictionary.keys
  end

  def licence_names(licence_dictionary=@dictionary)
    @licence_names ||= licence_dictionary.map { |_, value| value['title'] }
  end

  private

  def dictionary_filepath
    File.join(Rails.root, "config", "dictionaries", "licences.yml")
  end

end
