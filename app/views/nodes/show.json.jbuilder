# frozen_string_literal: true

json.extract! @node, :id, :name, :member_status, :country_code, :home_page, :twitter, :created_at, :updated_at

json.staff do
  @node.staff.map do |staff|
    {
      name: staff.name,
      role: staff.role,
      email: staff.email
    }
  end
end
