class DifficultyDictionary < Dictionary

  DEFAULT_FILE = "difficulty.yml"

  private

  def dictionary_filepath
    begin
      result = File.join(Rails.root, "config", "dictionaries", TeSS::Config.dictionaries['difficulty'])
      raise "file not found" if !File.file?(result)
    rescue
      result = File.join(Rails.root, "config", "dictionaries", DEFAULT_FILE)
    end
    return result
  end

end
