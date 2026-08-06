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
    host = space.try(:host) || TeSS::Config.base_uri.host

    Devise.omniauth_configs.select do |_provider, config|
      Array(config.options[:redirect_uris]).any? do |uri|
        TessOmniauthRedirectUris.valid_login_domain?(URI.parse(uri).host, host)
      end
    end
  end

  def space_supports_omniauth?(space = current_space)
    omniauth_providers_for_space(space).any?
  end

  # ORCID auth requires same-site cookies, so only allow default space
  # or spaces under the configured base domain.
  def space_supports_orcid_auth?(space = current_space)
    host = space.try(:host) || TeSS::Config.base_uri.host
    config = Rails.application.config.secrets.orcid
    redirect_uris = TessOmniauthRedirectUris.normalize(
      config[:redirect_uri],
      "#{TeSS::Config.base_url.chomp('/')}/orcid/callback"
    )

    redirect_uris.any? do |uri|
      TessOmniauthRedirectUris.valid_login_domain?(URI.parse(uri).host, host)
    end
  end
end
