# frozen_string_literal: true

class NodeSerializer < ApplicationSerializer
  attributes :id, :slug, :name, :member_status, :country_code, :home_page, :staff, :twitter, :created_at, :updated_at

  has_many :content_providers

  def staff
    object.staff.map do |staff|
      {
        name: staff.name,
        role: staff.role,
        email: staff.email
      }
    end
  end
end
