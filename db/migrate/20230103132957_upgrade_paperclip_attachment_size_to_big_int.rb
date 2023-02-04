# frozen-string-literal: true

# In 2018 paperclip migrated from integer to bigint for attachment file size
# since some uploads over 2GB could exceed this size. See this commit:
# https://github.com/thoughtbot/paperclip/commit/34ec355e43e91c63288aab956a604f17471d4e59
# this prevents us from getting a consistent database schema after migration
# and is generally a good idea to change.
class UpgradePaperclipAttachmentSizeToBigInt < ActiveRecord::Migration[6.1]
  # if this was already a bigint the alter-column will not do anything
  def up
    change_column :collections, :image_file_size, :bigint
    change_column :content_providers, :image_file_size, :bigint
    change_column :staff_members, :image_file_size, :bigint
  end

  # this migration should perform no action when migrating down
  # unless your paperclip version is below 6.1.0
  def down; end
end
