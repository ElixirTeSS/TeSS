# Dictionary of Materials Status
class MaterialStatusDictionary < Dictionary

  DEFAULT_FILE = 'material_status.yml'

  private

  def dictionary_filepath
    get_file_path 'material_status', DEFAULT_FILE
  end

end