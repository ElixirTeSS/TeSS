# The helper for Content Providers
module ContentProvidersHelper
  CONTENT_PROVIDERS_INFO = I18n.t('info.providers.description').freeze

  def content_providers_info
    format(CONTENT_PROVIDERS_INFO)
  end
end
