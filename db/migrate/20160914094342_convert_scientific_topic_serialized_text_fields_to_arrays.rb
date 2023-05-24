# frozen_string_literal: true

require 'yaml'

class ScientificTopic < ApplicationRecord; end

class ConvertScientificTopicSerializedTextFieldsToArrays < ActiveRecord::Migration[4.2]
  def up
    fields = [:synonyms, :definitions, :parents, :consider,
              :has_alternative_id, :has_broad_synonym, :has_dbxref,
              :has_exact_synonym, :has_related_synonym, :has_subset,
              :replaced_by, :subset_property, :has_narrow_synonym,
              :in_subset, :in_cyclic]

    fields.each do |field|
      add_column :scientific_topics, "#{field}2".to_sym, :string, array: true, default: []
    end

    # De-serialize data and copy into new columns
    Rails.logger.debug 'Converting serialized scientific topic attributes to Postgres arrays'
    ScientificTopic.transaction do
      ScientificTopic.all.each do |e|
        fields.each do |field|
          e.update_column("#{field}2".to_sym, YAML.safe_load(e.send(field))) if e.send(field).present?
          Rails.logger.debug '.'
        end
      end
    end

    fields.each do |field|
      remove_column :scientific_topics, field
      rename_column :scientific_topics, "#{field}2".to_sym, field
    end
  end

  def down
    fields = [:synonyms, :definitions, :parents, :consider,
              :has_alternative_id, :has_broad_synonym, :has_dbxref,
              :has_exact_synonym, :has_related_synonym, :has_subset,
              :replaced_by, :subset_property, :has_narrow_synonym,
              :in_subset, :in_cyclic]

    fields.each do |field|
      add_column :scientific_topics, "#{field}2".to_sym, :text
    end

    # Re-serialize data and copy into old columns
    Rails.logger.debug 'Converting Postgres arrays to serialized attributes'
    ScientificTopic.transaction do
      ScientificTopic.all.each do |e|
        fields.each do |field|
          e.update_column("#{field}2".to_sym, e.send(field).to_yaml) if e.send(field).present?
          Rails.logger.debug '.'
        end
      end
    end

    fields.each do |field|
      remove_column :scientific_topics, field
      rename_column :scientific_topics, "#{field}2".to_sym, field
    end
  end
end
