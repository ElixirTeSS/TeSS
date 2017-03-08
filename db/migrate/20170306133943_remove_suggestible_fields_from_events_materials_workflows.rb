class RemoveSuggestibleFieldsFromEventsMaterialsWorkflows < ActiveRecord::Migration
  def change
    remove_reference :materials, :suggestible, polymorphic: true
    remove_reference :events, :suggestible, polymorphic: true
    remove_reference :workflows, :suggestible, polymorphic: true
  end
end
