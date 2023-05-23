# frozen_string_literal: true

class AddDefaultValueToLicenseInWorkflows < ActiveRecord::Migration[4.2]
  def change
    change_column_default :workflows, :licence, 'notspecified'
    Workflow.find_each do |wf|
      wf.update_column(:licence, 'notspecified') if wf.licence.blank?
    end
  end
end
