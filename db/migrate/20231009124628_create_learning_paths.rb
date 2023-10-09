class CreateLearningPaths < ActiveRecord::Migration[7.0]
  def change
    create_table :learning_paths do |t|
      t.text :title
      t.text :description
      t.string :doi
      t.string :target_audience, default: [], array: true
      t.string :authors, default: [], array: true
      t.string :contributors, default: [], array: true
      t.string :licence, default: 'notspecified'
      t.string :difficulty_level, default: 'notspecified'
      t.string :slug
      t.references :user, index: true, foreign_key: true
      t.references :content_provider, index: true, foreign_key: true
      t.string :keywords, default: [], array: true
      t.text :prerequisites
      t.text :learning_objectives
      t.string :status
      t.string :learning_path_type
      t.timestamps
    end

    add_index :learning_paths, :slug, unique: true
  end
end
