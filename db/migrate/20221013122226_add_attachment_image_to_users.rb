class AddAttachmentImageToUsers < ActiveRecord::Migration[6.1]
  def self.up
    change_table :users do |t|
      t.text :image_url, null: true, default: nil
      t.attachment :image
    end
  end

  def self.down
    remove_column :users, :image_url
    remove_attachment :users, :image
  end
end
