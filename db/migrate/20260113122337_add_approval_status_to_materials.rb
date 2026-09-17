class AddApprovalStatusToMaterialsAndEvents < ActiveRecord::Migration[7.2]
  def change
    add_column :materials, :approval_status, :string
    add_column :events, :approval_status, :string
  end
end
