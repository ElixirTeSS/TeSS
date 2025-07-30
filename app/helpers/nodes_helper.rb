# The helper for Nodes classes
module NodesHelper
  NODES_INFO = I18n.t('info.nodes.description').freeze

  def nodes_info
    format(NODES_INFO, site_name: TeSS::Config.site['title_short'])
  end

  def add_node_staff_button(form, target)
    link_to('#', data: { role: 'add-node-staff-button', target: target }, class: 'btn btn-default') do
      '<i class="fa fa-plus"></i> Add staff'.html_safe
    end +
    content_tag(:div, style: 'display: none', data: { role: 'add-node-staff-template' }) do
      render partial: 'staff_form', locals: { form: form, staff_member: StaffMember.new }
    end
  end

  def node_staff_list(staff, show_role = true, link: true)
    if staff.any?
      staff.map do |staff_member|
        text = "#{staff_member.name}"
        text += " (#{staff_member.role})" if show_role && !staff_member.role.blank?
        !staff_member.email.blank? && link ? mail_to(staff_member.email, text) : text
      end.join(', ').html_safe
    else
      empty_tag(:span, 'none specified')
    end
  end

  def country_flag(country_code, options = {})
    image_tag("nodes/flags/#{country_code}.png", options) if country_code.present?
  end

  def countries_options_for_select
    Node::COUNTRIES.map {|k, v| [v + " (#{k})", k] }.sort_by { |o| o[0] }
  end

  def elixir_node_icon(opts = {})
    opts.reverse_merge!({
                          alt: 'ELIXIR node event',
                          title: 'ELIXIR node event',
                          class: 'elixir-node-icon' })
    image_tag ApplicationHelper::DEFAULT_IMAGE_FOR_MODEL['Node'], opts
  end

end
