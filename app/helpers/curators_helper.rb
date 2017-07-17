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

end
