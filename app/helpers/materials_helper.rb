# The helper for Materials classes
module MaterialsHelper
  MATERIALS_INFO = "In the context of #{TeSS::Config.site['title_short']}, a training material is a link to a single\
  online training material sourced by a content provider (such as a text on a Web page, presentation, video, etc.) along\
  with description and other meta information (e.g. ontological categorization, keywords, etc.).\n\n
  Materials can be added manually or automatically harvested from a provider's website.\n\n\
  If your website contains training materials that you wish to include in #{TeSS::Config.site['title_short']},\
  please contact the support team (<a href='#{TeSS::Config.contact_email}'>#{TeSS::Config.contact_email}</a>)\
  for further details.".freeze

  ELEARNING_MATERIALS_INFO = "e-Learning materials are curated materials focused on e-Learning.\n\n"\
  "If your website contains e-Learning materials that you wish to include in #{TeSS::Config.site['title_short']},\
  please contact the support team (<a href='#{TeSS::Config.contact_email}'>#{TeSS::Config.contact_email}</a>)\
  for further details.".freeze

  TOPICS_INFO = "#{TeSS::Config.site['title_short']} generates a scientific topic suggestion for each resource registered. It does this by
  passing the description and title of the resource to the Bioportal Annotator Web service.
  The Annotator Web service finds EDAM terms that match terms in the text. You can then accept or reject these terms in #{TeSS::Config.site['title_short']}.

Accepting will add a topic to the resource and rejecting will remove the suggestion permanently"
  # Returns an array of two-element arrays of licences ready to be used in options_for_select() for generating option/select tags
  # [['Licence 1 full name','Licence 1 abbreviation'], ['Licence 2 full name','Licence 2 abbreviation'], ...]
  def licence_options_for_select
    LicenceDictionary.instance.options_for_select.sort_by { |x| x[0] }
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
    Edam::Ontology.instance.all_topics.map(&:preferred_label)
  end

  def material_status_title_for_label(label)
    MaterialStatusDictionary.instance.lookup_value(label, 'title') || label
  end

  def material_type_title_for_label(label)
    MaterialTypeDictionary.instance.lookup_value(label, 'title') || label
  end

  def target_audience_title_for_label(label)
    TargetAudienceDictionary.instance.lookup_value(label, 'title') || label
  end

  def display_difficulty_level(resource)
    value = resource.send("difficulty_level")
    if value == 'beginner'
      "• " + value
    elsif value == 'intermediate'
      "•• " + value
    elsif value == 'advanced'
      "••• " + value
    else
      ""
    end
  end

  def display_attribute(resource, attribute, show_label: true, markdown: false) # resource e.g. <#Material> & symbol e.g. :target_audience
    value = resource.send(attribute)
    value = render_markdown(value) if markdown
    value = yield(value) if block_given? && value.present?
    string = "<p class=\"#{attribute}#{show_label ? ' no-spacing' : ''}\">"
    unless value.blank? || value.try(:strip) == 'License Not Specified'
      string << "<strong class='text-primary'> #{resource.class.human_attribute_name(attribute)}: </strong>" if show_label
      string << value.to_s
    end
    string << '</p>'
    string.html_safe
  end

  def display_attribute_no_label(resource, attribute, markdown: false, &block) # resource e.g. <#Material> & symbol e.g. :target_audience
    display_attribute(resource, attribute, markdown: markdown, show_label: false, &block)
  end
end
