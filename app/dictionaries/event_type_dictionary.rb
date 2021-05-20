class EventTypeDictionary < Dictionary

  DEFAULT_FILE = "event_types.yml"

  private

  def dictionary_filepath
    begin
      result = File.join(Rails.root, "config", "dictionaries", TeSS::Config.dictionaries['event_types'])
      raise "file not found" if !File.file?(result)
    rescue
      result = File.join(Rails.root, "config", "dictionaries", DEFAULT_FILE )
    end
    return result
  end

end
