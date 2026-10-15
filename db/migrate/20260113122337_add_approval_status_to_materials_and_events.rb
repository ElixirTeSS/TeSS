class AddApprovalStatusToMaterialsAndEvents < ActiveRecord::Migration[7.2]
  def change
    add_column :materials, :approval_status, :string, default: '2'
    add_column :events, :approval_status, :string, default: '2'

    reversible do |dir|
      dir.up do
        # Backfill existing records (will be NULL on existing rows when adding a column)
        Material.unscoped.where(approval_status: nil).update_all(approval_status: '2')
        Event.unscoped.where(approval_status: nil).update_all(approval_status: '2')
      end
    end
  end
end
