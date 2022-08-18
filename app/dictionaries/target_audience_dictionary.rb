# Dictionary of Target Audiences
class TargetAudienceDictionary < Dictionary

  DEFAULT_FILE = 'target_audience.yml'

  private

  def dictionary_filepath
    get_file_path 'target_audience', DEFAULT_FILE
  end

end