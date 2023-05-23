# frozen_string_literal: true

class ScientificTopic < ApplicationRecord; end

class EditSuggestion < ApplicationRecord
  has_and_belongs_to_many :scientific_topics_old, class_name: 'ScientificTopic',
                                                  join_table: 'edit_suggestions_scientific_topics'
end

class ConvertEditSuggestionScientificTopicsToNewFormat < ActiveRecord::Migration[4.2]
  def up
    Rails.logger.debug 'Creating ScientificTopicLinks for EditSuggestions'
    EditSuggestion.all.each do |es|
      es.scientific_topics_old.each do |topic|
        unless es.scientific_topic_links.where(term_uri: topic.class_id).exists?
          es.scientific_topic_links.create(term_uri: topic.class_id)
        end
      end
      Rails.logger.debug '.'
    end
    puts
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
