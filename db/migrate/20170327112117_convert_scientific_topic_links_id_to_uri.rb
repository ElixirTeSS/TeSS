# frozen_string_literal: true

class ScientificTopicLink < ApplicationRecord
  belongs_to :scientific_topic
end

class ScientificTopic < ApplicationRecord; end

class ConvertScientificTopicLinksIdToUri < ActiveRecord::Migration[4.2]
  def up
    add_column :scientific_topic_links, :term_uri, :string
    add_index :scientific_topic_links, :term_uri

    Rails.logger.debug 'Converting scientific topic link IDs to URIs'
    ScientificTopicLink.transaction do
      ScientificTopicLink.all.each do |l|
        topic = l.scientific_topic
        l.update_column(:term_uri, topic.class_id) if topic&.class_id
        Rails.logger.debug '.'
      end
    end
    puts

    remove_reference :scientific_topic_links, :scientific_topic
  end

  def down
    add_reference :scientific_topic_links, :scientific_topic
    remove_index :scientific_topic_links, :term_uri
    remove_column :scientific_topic_links, :term_uri
  end
end
