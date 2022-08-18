class AddLearningObjectiveToMaterials < ActiveRecord::Migration[5.2]
  def change
    add_column :materials, :learning_objectives, :text
  end
end
