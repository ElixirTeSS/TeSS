class UpdatePolymorphicFieldsReferencingPackages < ActiveRecord::Migration[6.1]
  POLYMORPHIC = {
    activities: [:trackable_type, :owner_type, :recipient_type],
    collaborations: [:resource_type],
    edit_suggestions: [:suggestible_type],
    external_resources: [:source_type],
    field_locks: [:resource_type],
    friendly_id_slugs: [:sluggable_type],
    link_monitors: [:lcheck_type],
    node_links: [:resource_type],
    ontology_term_links: [:resource_type],
    stars: [:resource_type],
    subscriptions: [:subscribable_type],
    widget_logs: [:resource_type]
  }

  def up
    update_fields('Package', 'Collection')
  end

  def down
    update_fields('Collection', 'Package')
  end

  private

  def update_fields(from, to)
    POLYMORPHIC.each do |table, fields|
      fields.each do |field|
        update_field(table, field, from, to)
      end
    end
  end

  def update_field(table, field, from, to)
    ActiveRecord::Base.connection.execute("UPDATE #{table} SET #{field} = '#{to}' WHERE #{field} = '#{from}'")
  end
end
