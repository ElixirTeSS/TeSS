# Dictionary of Event Types
class EventTypeDictionary < Dictionary

  DEFAULT_FILE = 'event_types.yml'

  private

  def dictionary_filepath
    get_file_path 'event_types', DEFAULT_FILE
  end

end
