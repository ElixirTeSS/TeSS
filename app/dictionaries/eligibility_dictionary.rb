class EligibilityDictionary < Dictionary

  DEFAULT_FILE  = "eligibility.yml"

  private

  def dictionary_filepath
    begin
      result = File.join(Rails.root, "config", "dictionaries", TeSS::Config.dictionaries['eligibility'])
      raise "file not found" if !File.file?(result)
    rescue
      result = File.join(Rails.root, "config", "dictionaries", DEFAULT_FILE)
    end
    return result
  end

end
