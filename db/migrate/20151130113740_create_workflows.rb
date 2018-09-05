class CreateWorkflows < ActiveRecord::Migration[4.2]
  def change
    create_table :workflows do |t|
      t.string :title
      t.string :description
      t.references :user, index: true, foreign_key: true
      t.json :workflow_content

      t.timestamps null: false
    end
  end
end
