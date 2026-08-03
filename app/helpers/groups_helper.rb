module GroupsHelper
  def groups_info
    I18n.t('info.groups.description',
        link: I18n.t('info.groups.link'),
        url: registering_resources_path(anchor: 'automatic'))
    end
end
