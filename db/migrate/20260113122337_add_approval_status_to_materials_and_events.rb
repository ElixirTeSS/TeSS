class AddApprovalStatusToMaterialsAndEvents < ActiveRecord::Migration[7.2]
  def change
    add_column :materials, :approval_status, :string, default: 'approved'
    add_column :events, :approval_status, :string, default: 'approved'

    reversible do |dir|
      dir.up do
        # Backfill existing records (will be NULL on existing rows when adding a column)
        Material.unscoped.where(approval_status: nil).update_all(approval_status: 'approved')
        Event.unscoped.where(approval_status: nil).update_all(approval_status: 'approved')
      end
    end
  end
end
