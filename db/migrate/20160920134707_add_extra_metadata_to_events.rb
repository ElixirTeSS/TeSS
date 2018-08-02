class AddExtraMetadataToEvents < ActiveRecord::Migration[4.2]
  def change
    add_column :events, :target_audience, :string, array: true, default: []
    add_column :events, :capacity, :integer
    add_column :events, :eligibility, :string, array: true, default: []
    add_column :events, :contact, :text
  end
end
