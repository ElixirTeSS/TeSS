# The helper for Materials classes
module TrainersHelper
  TRAINERS_INFO = "In the context of #{TeSS::Config.site['title_short']}, a trainer...".freeze

  # Returns an array of two-element arrays of licences ready to be used in options_for_select()
  # for generating option/select tags
  def trainer_experience_options_for_select
    TrainerExperienceDictionary.instance.options_for_select
  end

  def trainer_experience_title_for_key(key)
    TrainerExperienceDictionary.instance.lookup_value(key, 'title')
  end

end
