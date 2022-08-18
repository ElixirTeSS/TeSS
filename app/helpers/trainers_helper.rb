# The helper for Materials classes
module TrainersHelper
  TRAINERS_INFO = "#{TeSS::Config.site['title_short']} provides a facility that allows registered users to " +
    "provide information about their training experience " +
    "and make this publicly available via the Trainers Register.".freeze

  # Returns an array of two-element arrays of licences ready to be used in options_for_select()
  # for generating option/select tags
  def trainer_experience_options_for_select
    TrainerExperienceDictionary.instance.options_for_select
  end

  def trainer_experience_title_for_key(key)
    TrainerExperienceDictionary.instance.lookup_value(key, 'title')
  end

end
