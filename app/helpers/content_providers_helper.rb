module ContentProvidersHelper
  def html_logo_for(content_provider)
    if content_provider.blank?
      return ''
    else
      return link_to(image_tag(get_content_provider_logo_url(content_provider), :class=>'content_provider_logo'), content_provider)
    end
  end
end
