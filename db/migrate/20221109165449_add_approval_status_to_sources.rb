class AddApprovalStatusToSources < ActiveRecord::Migration[6.1]
  def up
    add_column :sources, :approval_status, :integer
    ActiveRecord::Base.connection.execute("UPDATE sources SET approval_status = 2 WHERE approval_status IS NULL")
  end

  def down
    remove_column :sources, :approval_status, :integer
  end
end
