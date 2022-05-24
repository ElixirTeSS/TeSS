# Dictionary of Eligibility for Event categories
class EligibilityDictionary < Dictionary

  DEFAULT_FILE = 'eligibility.yml'

  private

  def dictionary_filepath
    get_file_path 'eligibility', DEFAULT_FILE
  end

end
