module MaterialsHelper
  MATERIALS_INFO = "In the context of TeSS, a training material is a link to a single online training material sourced by a content provider (such as a text on a Web page, presentation, video, etc.) along with description and other meta information (e.g. ontological categorization, keywords, etc.).\n\n"\
  "TeSS harvests materials automatically, including descriptions and other relevant meta-data made available by providers. Materials can also be registered manually.\n\n"\
  "If your website contains training materials that you wish to include in TeSS, please contact the TeSS team (<a href='mailto:tess @elixir-uk.info'>tess@elixir-uk.info</a>) for further details.".freeze

  # Returns an array of two-element arrays of licences ready to be used in options_for_select() for generating option/select tags
  # [['Licence 1 full name','Licence 1 abbreviation'], ['Licence 2 full name','Licence 2 abbreviation'], ...]
  def licence_options_for_select
    Tess::LicenceDictionary.instance.options_for_select
  end

  def licence_name_for_abbreviation(licence)
    if licence.blank?
      'License not specified'
    else
      Tess::LicenceDictionary.instance.lookup_value(licence, 'title')
    end
  end

  def difficulty_options_for_select
    Tess::DifficultyDictionary.instance.options_for_select
  end

  def difficulty_name_for_abbreviation(difficulty)
    if difficulty
      Tess::DifficultyDictionary.instance.lookup_value(difficulty, 'title')
    else
      'No difficulties available'
    end
  end

  def edam_names_for_autocomplete
    ScientificTopic.where.not(preferred_label: nil).map do |topic|
      { value: topic.preferred_label, data: topic.id }
    end
  end

  def scientific_topic_names_for_autocomplete
    ScientificTopic.where.not(preferred_label: nil).map(&:preferred_label)
  end

  def scientific_topic_ids_for_autocomplete
    ScientificTopic.where.not(preferred_label: nil).map(&:id)
  end

  def content_providers_list
    ContentProvider.all.map do |content_provider|
      link_to(content_provider.title, content_provider)
    end
  end

  def none_specified(resource, attribute)
    # return '' #comment to display all non specified fields
    "<p><b> #{resource.class.human_attribute_name(attribute)}: </b> #{empty_tag(:span, 'not specified')}".html_safe
  end

  def display_attribute(resource, attribute) # resource e.g. <#Material> & symbol e.g. :target_audience
    value = resource.send(attribute)

    if value.blank? || value.try(:strip) == 'notspecified'
      none_specified(resource, attribute)
    else
      string = "<p><b> #{resource.class.human_attribute_name(attribute)}: </b>"
      string << (block_given? ? yield(value) : value.to_s)

      (string + '</p>').html_safe
    end
  end
end
