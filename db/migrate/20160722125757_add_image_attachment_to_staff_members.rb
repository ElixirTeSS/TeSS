class AddImageAttachmentToStaffMembers < ActiveRecord::Migration[4.2]
  def change
    add_attachment :staff_members, :image
  end
end
