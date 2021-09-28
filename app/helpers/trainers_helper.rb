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
  
  def display_attribute(resource, attribute)
    value = resource.send(attribute)
    if value.blank? || value.try(:strip) == 'notspecified'
      string = "<p class=\"#{attribute}\">"
    elsif attribute.to_s.include? 'experience'
      string = "<p class=\"#{attribute}\"><b> #{resource.class.human_attribute_name(attribute)}: </b>"
      string << (block_given? ? yield(value) : trainer_experience_title_for_key(value).to_s)
    else
      string = "<p class=\"#{attribute}\"><b> #{resource.class.human_attribute_name(attribute)}: </b>"
      string << (block_given? ? yield(value) : value.to_s)
    end
    (string + '</p>').html_safe
  end
end
