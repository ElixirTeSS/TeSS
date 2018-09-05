class EligibilityDictionary < Dictionary

  private

  def dictionary_filepath
    File.join(Rails.root, "config", "dictionaries", "eligibility.yml")
  end

end
