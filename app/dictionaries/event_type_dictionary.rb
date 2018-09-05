class EventTypeDictionary < Dictionary

  private

  def dictionary_filepath
    File.join(Rails.root, "config", "dictionaries", "event_types.yml")
  end

end
