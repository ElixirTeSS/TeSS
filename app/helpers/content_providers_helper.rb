module ContentProvidersHelper
  def html_logo_for(content_provider, html_class=nil)
    if content_provider.blank?
      return ''
    else
      return link_to(image_tag(get_logo_url_for(content_provider), :class=>html_class), content_provider)
    end
  end
end
