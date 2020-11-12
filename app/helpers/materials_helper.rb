module MaterialsHelper
  MATERIALS_INFO = "In the context of TeSS, a training material is a link to a single online training material sourced by a content provider (such as a text on a Web page, presentation, video, etc.) along with description and other meta information (e.g. ontological categorization, keywords, etc.).\n\n"\
  "TeSS harvests materials automatically, including descriptions and other relevant meta-data made available by providers. Materials can also be registered manually.\n\n"\
  "If your website contains training materials that you wish to include in TeSS, please contact the TeSS team (<a href='#{TeSS::Config.contact_email}'>#{TeSS::Config.contact_email}</a>) for further details.".freeze

  ELEARNING_MATERIALS_INFO = "E-learning materials are curated materials focused on e-learning.\n\n"\
  "If your website contains e-learning materials that you wish to include in TeSS, please contact the TeSS team (<a href='#{TeSS::Config.contact_email}'>#{TeSS::Config.contact_email}</a>) for further details.".freeze

  TOPICS_INFO = "TeSS generates a scientific topic suggestion for each resource registered. It does this by
  passing the description and title of the resource to the Bioportal Annotator Web service.
The Annotator Web service finds EDAM terms that match terms in the text. You can then accept or reject these terms in TeSS.

Accepting will add a topic to the resource and rejecting will remove the suggestion permanently"
  # Returns an array of two-element arrays of licences ready to be used in options_for_select() for generating option/select tags
  # [['Licence 1 full name','Licence 1 abbreviation'], ['Licence 2 full name','Licence 2 abbreviation'], ...]
  def licence_options_for_select
    LicenceDictionary.instance.options_for_select
  end

  def licence_name_for_abbreviation(licence)
    LicenceDictionary.instance.lookup_value(licence, 'title')
  end

  def difficulty_options_for_select
    DifficultyDictionary.instance.options_for_select
  end

  def difficulty_name_for_abbreviation(difficulty)
    DifficultyDictionary.instance.lookup_value(difficulty, 'title')
  end

  def scientific_topic_names_for_autocomplete
    EDAM::Ontology.instance.all_topics.map(&:preferred_label)
  end

  def display_attribute(resource, attribute) # resource e.g. <#Material> & symbol e.g. :target_audience
    value = resource.send(attribute)
    if value.blank? || value.try(:strip) == 'notspecified'
      string = "<p class=\"#{attribute}\">"
    else
      string = "<p class=\"#{attribute}\"><b> #{resource.class.human_attribute_name(attribute)}: </b>"
      string << (block_given? ? yield(value) : value.to_s)
    end
    (string + '</p>').html_safe
  end
end
