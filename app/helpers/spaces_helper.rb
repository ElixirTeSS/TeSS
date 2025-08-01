# The helper for Spaces classes
module SpacesHelper
  SPACES_INFO = I18n.t('info.spaces.description').freeze

  def spaces_info
    format(SPACES_INFO, site_name: TeSS::Config.site['title_short'])
  end
end
