module HasLicence

  extend ActiveSupport::Concern

  included do
    validates :licence, controlled_vocabulary: { dictionary: LicenceDictionary.instance }

    if TeSS::Config.solr_enabled
      # :nocov:
      searchable do
        string :licence do
          LicenceDictionary.instance.lookup_value(self.licence, 'title')
        end
        text :licence
      end
      # :nocov:
    end
  end

  # Allows setting of the license either by using the key (CC-BY-4.0) #
  #  or license URL (https://creativecommons.org/licenses/by/4.0/)
  def licence= key_or_uri
    id = LicenceDictionary.instance.lookup_by(:url, key_or_uri).first if key_or_uri =~ URI::regexp
    key_or_uri = id if id

    super(key_or_uri)
  end

end
