class AddFieldsToEvents < ActiveRecord::Migration[5.2]
  def change
    add_column :events, :duration, :string
    add_column :events, :recognition, :text
    add_column :events, :learning_objectives, :text
  end
end
