# The helper for Materials classes
module MaterialsHelper
  def materials_info
    I18n.t('info.materials.description',
           link: link_to(I18n.t('info.materials.link'),
                         registering_resources_path(anchor: 'automatic')))
  end

  def elearning_materials_info
    I18n.t('info.elearning_materials.description',
           link: link_to(I18n.t('info.elearning_materials.link'),
                         registering_resources_path(anchor: 'automatic')))
  end

  def topics_info
    I18n.t('info.topics.description')
  end

  def learning_paths_info
    I18n.t('info.learning_paths.description',
           link: link_to(I18n.t('info.learning_paths.link'),
                         registering_learning_paths_path(anchor: 'register_paths')))
  end

  def learning_path_topics_info
    I18n.t('info.learning_path_topics.description',
           link: link_to(I18n.t('info.learning_path_topics.link'),
                         registering_learning_paths_path(anchor: 'topics')))
  end

  # Returns an array of two-element arrays of licences ready to be used in options_for_select() for generating option/select tags
  # [['Licence 1 full name','Licence 1 abbreviation'], ['Licence 2 full name','Licence 2 abbreviation'], ...]
  def licence_options_for_select
    LicenceDictionary.instance.grouped_options_for_select
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
    value = resource.send('difficulty_level')
    if value == 'beginner'
      '• ' + value
    elsif value == 'intermediate'
      '•• ' + value
    elsif value == 'advanced'
      '••• ' + value
    else
      ''
    end
  end

  def display_attribute(resource, attribute, show_label: true, title: nil, markdown: false, list: false, expandable: false)
    return if [
      TeSS::Config.feature['disabled'].include?(attribute.to_s),
      (TeSS::Config.feature['materials_disabled'].include?(attribute.to_s) && resource.is_a?(Material)),
      (TeSS::Config.feature['content_providers_disabled'].include?(attribute.to_s) && resource.is_a?(ContentProvider))
    ].any?

    value = resource.send(attribute)
    if markdown
      value = render_markdown(value)
    end
    if value.present?
      if list
        value = value.map do |v|
          html_escape(block_given? ? yield(v) : v)
        end
      else
        value = html_escape(block_given? ? yield(value) : value)
      end
    end
    string = "<p class=\"#{attribute}#{show_label ? ' no-spacing' : ''}\">"
    unless value.blank? || value.try(:strip) == 'License Not Specified'
      string << "<strong class='text-primary'> #{title || resource.class.human_attribute_name(attribute)}: </strong>" if show_label
      if list
        string << '<ul>'
        value.each do |v|
          string << "<li>#{v}</li>"
        end
        string << '</ul>'
      elsif expandable
        height_limit = expandable.is_a?(Numeric) ? expandable : nil
        string << "<div class=\"tess-expandable\"#{" data-height-limit=\"#{height_limit}\"" if height_limit}>" + value.to_s + '</div>'
      else
        string << value.to_s
      end
    end
    string << '</p>'
    string.html_safe
  end

  def display_attribute_no_label(resource, attribute, markdown: false, &block) # resource e.g. <#Material> & symbol e.g. :target_audience
    display_attribute(resource, attribute, markdown:, show_label: false, &block)
  end

  def embed_youtube(material)
    renderer = Renderers::Youtube.new(material)
    return unless renderer.can_render?

    content_tag(:div, class: 'embedded-content') do
      renderer.render_content.html_safe
    end
  end

  def keywords_and_topics(resource, limit: nil)
    tags = []

    %i[scientific_topic_names operation_names keywords].each do |field|
      tags |= resource.send(field) if resource.respond_to?(field)
    end

    limit_exceeded = limit && (tags.length > limit)
    tags = tags.first(limit) if limit

    elements = tags.map do |tag|
      content_tag(:span, tag, class: 'label label-info')
    end
    elements << '&hellip;' if limit_exceeded

    elements.join(' ').html_safe
  end
end
