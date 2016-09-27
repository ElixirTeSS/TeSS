class AddDefaultValueToLicenseInWorkflows < ActiveRecord::Migration
  def change
    change_column_default :workflows, :licence, 'notspecified'
    Workflow.find_each do |wf|
      if wf.licence.blank?
        wf.update_column(:licence, 'notspecified')
      end
    end
  end
end
