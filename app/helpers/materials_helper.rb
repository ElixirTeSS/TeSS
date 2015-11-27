module MaterialsHelper
  require 'licence_dictionary'

  # Returns an array of two-element arrays of licences ready to be used in options_for_select() for generating option/select tags
  # [['Licence 1 full name','Licence 1 abbreviation'], ['Licence 2 full name','Licence 2 abbreviation'], ...]
  def licence_options_for_select()
    TeSS::LicenceDictionary.instance.licence_options_for_select
  end

  def licence_name_for_abbreviation(licence)
    if licence
      TeSS::LicenceDictionary.instance.licence_name_for_abbreviation(licence)
    else
      'No licence found'
    end
  end

  def material_package_list(material)
    packages = []
    material.packages.each do |p| 
      packages << link_to(p.name, p)
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
end
