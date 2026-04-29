class AddUnorderedToLearningPaths < ActiveRecord::Migration[7.2]
  def change
    add_column :learning_paths, :unordered, :boolean, default: false, null: false
  end
end
