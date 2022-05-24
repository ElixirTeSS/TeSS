# Dictionary of Material Types
class MaterialTypeDictionary < Dictionary

  DEFAULT_FILE = 'material_type.yml'

  private

  def dictionary_filepath
    get_file_path 'material_type', DEFAULT_FILE
  end

end