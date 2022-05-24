# Dictionary of Trainer Experience
class TrainerExperienceDictionary < Dictionary

  DEFAULT_FILE = 'trainer_experience.yml'

  private

  def dictionary_filepath
    get_file_path 'trainer_experience', DEFAULT_FILE
  end

end
