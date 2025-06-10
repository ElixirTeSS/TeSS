class AddSpaceIdToTables < ActiveRecord::Migration[7.2]
  def change
    add_reference :materials, :space, foreign_key: true
    add_reference :events, :space, foreign_key: true
    add_reference :workflows, :space, foreign_key: true
    add_reference :collections, :space, foreign_key: true
    add_reference :learning_paths, :space, foreign_key: true
    add_reference :learning_path_topics, :space, foreign_key: true
  end
end
