# Dictionary of Eligibility for Event categories
class OnlineKeywordsDictionary < Dictionary

  DEFAULT_FILE = 'online_keywords.yml'

  private

  def dictionary_filepath
    get_file_path 'online_keywords', DEFAULT_FILE
  end

end
