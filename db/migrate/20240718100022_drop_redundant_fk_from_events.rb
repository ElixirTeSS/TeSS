class DropRedundantFkFromEvents < ActiveRecord::Migration[7.0]
  def up
    if ActiveRecord::Base.connection.column_exists?(:events, :llm_interaction_id)
      remove_reference :events, :llm_interaction, foreign_key: true
    end
  end

  def down
    unless ActiveRecord::Base.connection.column_exists?(:events, :llm_interaction_id)
      add_reference :events, :llm_interaction, foreign_key: true
    end
  end
end
