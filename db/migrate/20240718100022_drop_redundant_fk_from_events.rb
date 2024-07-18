class DropRedundantFkFromEvents < ActiveRecord::Migration[7.0]
  def change
    if ActiveRecord::Base.connection.column_exists?(:events, :llm_interaction_id)
      remove_reference :events, :llm_interaction, foreign_key: true
    end
  end
end
