# The helper for Spaces classes
module SpacesHelper
  def spaces_info
    I18n.t('info.spaces.description')
  end

  def space_feature_options
    Space::FEATURES.map { |f| [t("features.#{f}.short"), f] }
  end
end
