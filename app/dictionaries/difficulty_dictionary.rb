# Dictionary of difficulties from http://licenses.opendefinition.org/licenses/groups/all.json
# Converted to yaml and saved to config/dictionaries/difficulty.yml
class DifficultyDictionary < Dictionary

  private

  def dictionary_filepath
    File.join(Rails.root, "config", "dictionaries", "difficulty.yml")
  end

end
