module GroupsHelper
  def groups_info
    I18n.t('info.events.description',
        link: I18n.t('info.events.link'),
        url: registering_resources_path(anchor: 'automatic'))
    end
end
