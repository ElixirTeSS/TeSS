# The controller for actions related to the Ban model
module CuratorsHelper

  MAX_AGE_OPTIONS = [
    { period: nil, key: 'any' }.with_indifferent_access,
    { period: 1.week, key: 'week' }.with_indifferent_access,
    { period: 1.month, key: 'month' }.with_indifferent_access,
    { period: 1.year, key: 'year' }.with_indifferent_access
  ].freeze

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

  def max_age_options(selected_age = nil)
    array = MAX_AGE_OPTIONS.map do |age|
      [t("curation.users.filters.max_age.options.#{age[:key]}"), age[:period]&.iso8601]
    end

    options_for_select(array, selected_age)
  end

  def recent_approvals
    PublicActivity::Activity.where(key: 'user.change_role').where('created_at > ?', 3.months.ago).order('created_at DESC').select do |activity|
      [Role.rejected.id, Role.approved.id].include?(activity.parameters[:new])
    end.first(5)
  end

  def approval_message(role_id)
    if role_id == Role.approved.id
      text = t('curation.users.activity.approved')
      css_class = 'text-success'
    else
      text = t('curation.users.activity.rejected')
      css_class = 'text-danger'
    end

    content_tag(:span, text, class: css_class)
  end
end
