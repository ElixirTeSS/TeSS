class AddCpIdToEvents < ActiveRecord::Migration
  def change
    add_column :events, :content_provider_id, :integer
  end
end
