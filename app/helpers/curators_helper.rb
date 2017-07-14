module CuratorsHelper

  def print_curation_action(action)
    resource, action = action.split('.')
    if action
      action, topic = action.split('_')
      action += 'ed'
      return "Number of #{topic}s #{action} to #{resource}s"
    else
      return resource
    end
  end

end
