module I18n
  class << self
    alias original_translate translate

    def translate(key, **options)
      defaults = { site_name: TeSS::Config.site['title_short'],
                    repository: TeSS::Config.site['repository'],
                    data_license: TeSS::Config.site['data_license'] }
      original_translate(key, **defaults.merge(options))
    end
    alias t translate
  end
end
