# Dictionary of Keywords
class KeywordsDictionary < Dictionary

  DEFAULT_FILE = 'keywords.yml'

  def dictionary_filepath
    get_file_path 'keywords', DEFAULT_FILE
  end

end