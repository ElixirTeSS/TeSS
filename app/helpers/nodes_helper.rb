module NodesHelper

  def add_node_staff_button(form, target)
    link_to('#', data: { role: 'add-node-staff-button', target: target }, class: 'btn btn-default') do
      '<i class="fa fa-plus"></i> Add staff'.html_safe
    end +
    content_tag(:div, style: 'display: none', data: { role: 'add-node-staff-template' }) do
      render partial: 'staff_form', locals: { form: form, staff_member: StaffMember.new }
    end
  end

end
