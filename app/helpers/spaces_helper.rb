# The helper for Spaces classes
module SpacesHelper
  def spaces_info
    I18n.t('info.spaces.description')
  end

  def space_feature_options
    Space::FEATURES.select do |f|
      TeSS::Config.feature[f]
    end.map do |f|
      [t("features.#{f}.short"), f]
    end
  end

  def space_supports_omniauth?(space = current_space)
    space.nil? || space.default? || space.is_subdomain?(TeSS::Config.base_uri.domain)
  end
end
