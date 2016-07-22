class AddImageAttachmentToStaffMembers < ActiveRecord::Migration
  def change
    add_attachment :staff_members, :image
  end
end
