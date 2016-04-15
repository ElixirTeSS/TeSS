require 'licence_dictionary'
require 'difficulty_dictionary'
require 'edam_dictionary'

module MaterialsHelper

  # Returns an array of two-element arrays of licences ready to be used in options_for_select() for generating option/select tags
  # [['Licence 1 full name','Licence 1 abbreviation'], ['Licence 2 full name','Licence 2 abbreviation'], ...]
  def licence_options_for_select()
    TeSS::LicenceDictionary.instance.licence_options_for_select
  end

  def licence_name_for_abbreviation(licence)
    unless licence.blank?
      TeSS::LicenceDictionary.instance.licence_name_for_abbreviation(licence)
    else
      'License not specified'
    end
  end

  def difficulty_options_for_select()
    TeSS::DifficultyDictionary.instance.difficulty_options_for_select
  end

  def difficulty_name_for_abbreviation(difficulty)
    if difficulty
      TeSS::DifficultyDictionary.instance.difficulty_name_for_abbreviation(difficulty)
    else
      'No difficulties available'
    end
  end

  def edam_names_for_autocomplete()
    return ScientificTopic.all.inject([]) do |topics,topic|
      topics + [:value => topic.preferred_label, :data => topic.id] unless topic.preferred_label.blank?
    end
  end

  def scientific_topic_names_for_autocomplete()
    return ScientificTopic.all.inject([]) do |topics,topic|
      topics << topic.preferred_label unless topic.preferred_label.blank?
    end
  end

  def scientific_topic_ids_for_autocomplete()
    return ScientificTopic.all.inject([]) do |topics,topic|
      topics << topic.id unless topic.preferred_label.blank?
    end
  end

  def material_package_list(material)
    packages = []
    material.packages.each do |p| 
      packages << link_to(p.title, p)
    end
    return packages
  end

  def content_providers_list
    cps = []
    ContentProvider.all.each do |content_provider|
      cps << link_to(content_provider.title, content_provider)
    end
    return cps
  end

  def empty_tag (tag_symbol, text, style=nil)
    content_tag tag_symbol, text, :class=>"empty", :style=>style
  end
end
