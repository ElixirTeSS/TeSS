class AddPublicToLearningPaths < ActiveRecord::Migration[7.0]
  def change
    add_column :learning_paths, :public, :boolean, default: true
  end
end
