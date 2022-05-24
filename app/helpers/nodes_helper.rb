# The helper for Nodes classes
module NodesHelper

  NODES_INFO = "ELIXIR is a pan-European research infrastructure consisting of the Hub and a number of, primarily,national nodes that provide services to their local communities.\n\n"+

      "Select a node to find out more about its training events, training provision, staff and member institutions."

  def add_node_staff_button(form, target)
    link_to('#', data: { role: 'add-node-staff-button', target: target }, class: 'btn btn-info') do
      '<i class="fa fa-plus"></i> Add staff'.html_safe
    end +
    content_tag(:div, style: 'display: none', data: { role: 'add-node-staff-template' }) do
      render partial: 'staff_form', locals: { form: form, staff_member: StaffMember.new }
    end
  end

  def node_staff_list(staff, show_role = true)
    if staff.any?
      staff.map do |staff_member|
        text = "#{staff_member.name}"
        text += " (#{staff_member.role})" if show_role && !staff_member.role.blank?
        !staff_member.email.blank? ? mail_to(staff_member.email, text) : text
      end.join(', ').html_safe
    else
      empty_tag(:span, 'none specified')
    end
  end

  def country_flag(country_code, options = {})
    image_tag "nodes/flags/#{country_code}.png", options
  end

  def countries_options_for_select
    Node::COUNTRIES.map {|k, v| [v + " (#{k})", k] }.to_h
  end

end
