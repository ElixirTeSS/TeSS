class BackfillContentProviderFieldLocks < ActiveRecord::Migration[8.1]
  class MigrationContentProvider < ApplicationRecord
    self.table_name = 'content_providers'
  end

  class MigrationFieldLock < ApplicationRecord
    self.table_name = 'field_locks'
  end

  FIELDS_TO_LOCK = %w[title url contact description content_provider_type keywords image].freeze

  def up
    MigrationContentProvider.find_each do |provider|
      fields = fields_with_content(provider)
      fields.each do |field|
        MigrationFieldLock.find_or_create_by!(
          resource_type: 'ContentProvider',
          resource_id: provider.id,
          field: field
        )
      end
    end
  end

  def down
    MigrationFieldLock.where(resource_type: 'ContentProvider', field: FIELDS_TO_LOCK).delete_all
  end

  private

  def fields_with_content(provider)
    fields = []
    fields << 'title' if provider.title.present?
    fields << 'url' if provider.url.present?
    fields << 'contact' if provider.contact.present?
    fields << 'description' if provider.description.present?
    fields << 'content_provider_type' if provider.content_provider_type.present?
    fields << 'keywords' if provider.keywords.present? && provider.keywords.any?
    fields << 'image' if provider.image_file_name.present? || provider.image_url.present?
    fields
  end
end
