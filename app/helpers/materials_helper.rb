module MaterialsHelper
  require File.expand_path(Rails.root.join('lib', 'tess', 'licence_dictionary.rb'))

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

end
