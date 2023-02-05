module HasLicence

  extend ActiveSupport::Concern

  included do
    validates :licence, controlled_vocabulary: { dictionary: 'LicenceDictionary' }

    # :nocov:
    searchable if: -> (_) { TeSS::Config.solr_enabled } do
      text :licence
      string :licence do
        LicenceDictionary.instance.lookup_value(self.licence, 'title')
      end
    end
    # :nocov:
  end

  # Allows setting of the license either by using the key (CC-BY-4.0) #
  #  or license URL (https://creativecommons.org/licenses/by/4.0/)
  def licence=(key_or_uri)
    id = LicenceDictionary.instance.lookup_uri(key_or_uri)

    super(id || key_or_uri)
  end

end
