module ContentProvidersHelper
  def html_logo_for(content_provider)
    unless content_provider.nil?
      return link_to(image_tag(content_provider.logo_url, :class=>'content_provider_logo'), content_provider)
    end
  end
end
