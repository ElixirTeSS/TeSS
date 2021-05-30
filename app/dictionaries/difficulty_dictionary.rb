# Dictionary of Material Difficulty categories
class DifficultyDictionary < Dictionary

  DEFAULT_FILE = 'difficulty.yml'

  private

  def dictionary_filepath
    get_file_path'difficulty', DEFAULT_FILE
  end

end
