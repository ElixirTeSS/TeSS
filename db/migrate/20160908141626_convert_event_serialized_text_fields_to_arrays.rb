# frozen_string_literal: true

require 'yaml'

class ConvertEventSerializedTextFieldsToArrays < ActiveRecord::Migration[4.2]
  def up
    # Add new columns
    add_column :events, :keywords2, :string, array: true, default: []
    add_column :events, :category2, :string, array: true, default: []
    add_column :events, :field2, :string, array: true, default: []

    # De-serialize data and copy into new columns
    Rails.logger.debug 'Converting serialized attributes to Postgres arrays'
    Event.transaction do
      Event.all.each do |e|
        e.update_column(:keywords2, YAML.safe_load(e.keywords)) if e.keywords.present?
        e.update_column(:category2, YAML.safe_load(e.category)) if e.category.present?
        e.update_column(:field2, YAML.safe_load(e.field)) if e.field.present?
        Rails.logger.debug '.'
      end
    end

    # Delete old columns
    remove_column :events, :keywords
    rename_column :events, :keywords2, :keywords
    remove_column :events, :category
    rename_column :events, :category2, :category
    remove_column :events, :field
    rename_column :events, :field2, :field
  end

  def down
    # Add old columns
    add_column :events, :keywords2, :text
    add_column :events, :category2, :text
    add_column :events, :field2, :text

    # Re-serialize data and copy into old columns
    Rails.logger.debug 'Converting Postgres arrays to serialized attributes'
    Event.transaction do
      Event.all.each do |e|
        e.update_column(:keywords2, e.keywords.to_yaml) unless e.keywords.empty?
        e.update_column(:category, e.category2.to_yaml) unless e.category2.empty?
        e.update_column(:field, e.field2.to_yaml) unless e.field2.empty?
        Rails.logger.debug '.'
      end
    end

    # Delete new columns
    remove_column :events, :keywords
    rename_column :events, :keywords2, :keywords
    remove_column :events, :category
    rename_column :events, :category2, :category
    remove_column :events, :field
    rename_column :events, :field2, :field
  end
end
