class CreateCollaborations < ActiveRecord::Migration
  def change
    create_table :collaborations do |t|
      t.references :user, index: true, foreign_key: true
      t.references :resource, polymorphic: true, index: true
    end
  end
end
