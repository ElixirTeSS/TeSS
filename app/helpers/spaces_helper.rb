# The helper for Spaces classes
module SpacesHelper
  def spaces_info
    I18n.t('info.spaces.description')
  end

  def space_tag(resource)
    if TeSS::Config.feature['spaces'] && resource.space && !resource.space.default? && resource.space != current_space
      content_tag(:span, class: 'label label-info space-tag', style: 'position: absolute; right: -5px; top: -5px;') do
        content_tag(:i, '', class: 'fa fa-share-square') + ' ' + resource.space.title
      end
    end
  end

  def space_feature_options
    Space::FEATURES.select do |f|
      TeSS::Config.feature[f]
    end.map do |f|
      [t("features.#{f}.short"), f]
    end
  end

  def omniauth_providers_for_space(space = current_space)
    host = space&.host || TeSS::Config.base_uri.host

    Devise.omniauth_configs.select do |_provider, config|
      default_redirect_uri = config.options.dig(:client_options, :redirect_uri)
      extra_redirect_uris = Array(config.options[:extra_redirect_uris])

      [default_redirect_uri, *extra_redirect_uris].compact_blank.any? do |uri|
        URI.parse(uri).host == host
      rescue URI::InvalidURIError
        false
      end
    end
  end

  def space_supports_omniauth?(space = current_space)
    omniauth_providers_for_space(space).any?
  end
end
