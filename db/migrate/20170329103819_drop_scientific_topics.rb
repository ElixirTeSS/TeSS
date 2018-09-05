class DropScientificTopics < ActiveRecord::Migration[4.2]
  def up
    drop_table :scientific_topics
  end

  def down
    create_table "scientific_topics" do |t|
      t.string   "preferred_label"
      t.boolean  "obsolete"
      t.string   "created_in"
      t.string   "documentation"
      t.string   "prefix_iri"
      t.text     "has_definition"
      t.string   "saved_by"
      t.string   "obsolete_since"
      t.datetime "created_at",                       null: false
      t.datetime "updated_at",                       null: false
      t.string   "class_id"
      t.string   "slug"
      t.string   "synonyms",            default: [],              array: true
      t.string   "definitions",         default: [],              array: true
      t.string   "parents",             default: [],              array: true
      t.string   "consider",            default: [],              array: true
      t.string   "has_alternative_id",  default: [],              array: true
      t.string   "has_broad_synonym",   default: [],              array: true
      t.string   "has_dbxref",          default: [],              array: true
      t.string   "has_exact_synonym",   default: [],              array: true
      t.string   "has_related_synonym", default: [],              array: true
      t.string   "has_subset",          default: [],              array: true
      t.string   "replaced_by",         default: [],              array: true
      t.string   "subset_property",     default: [],              array: true
      t.string   "has_narrow_synonym",  default: [],              array: true
      t.string   "in_subset",           default: [],              array: true
      t.string   "in_cyclic",           default: [],              array: true
    end
  end
end
