module CuratorsHelper

  def print_curation_action(action)
    resource, action = action.split('.')
    if action
      action, topic = action.split('_')
      action += 'ed'
      return "#{topic} suggestions #{action=='rejected' ? action + " from " : action + ' to '}#{resource}s".humanize
    else
      return resource.humanize
    end
  end

  def role_options(selected_role, scope: User)
    array = Role.all.map do |role|
      ["#{role.title.pluralize} (#{scope.with_role(role.name).count})", role.name]
    end

    options_for_select(array, selected_role.name)
  end
end
