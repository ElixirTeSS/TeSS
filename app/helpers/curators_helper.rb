# The controller for actions related to the Ban model
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

  def recent_approvals
    PublicActivity::Activity.where(key: 'user.change_role').where('created_at > ?', 3.months.ago).order('created_at DESC').select do |activity|
      [Role.rejected.id, Role.approved.id].include?(activity.parameters[:new])
    end.first(5)
  end

  def approval_message(role_id)
    if role_id == Role.approved.id
      text = 'approved'
      css_class = 'text-success'
    else
      text = 'rejected'
      css_class = 'text-danger'
    end

    content_tag(:span, text, class: css_class)
  end
end
