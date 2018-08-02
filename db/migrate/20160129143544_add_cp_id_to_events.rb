class AddCpIdToEvents < ActiveRecord::Migration[4.2]
  def change
    add_column :events, :content_provider_id, :integer
  end
end
