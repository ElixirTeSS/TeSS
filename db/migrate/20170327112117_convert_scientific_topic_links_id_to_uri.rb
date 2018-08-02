class ScientificTopicLink < ActiveRecord::Base
  belongs_to :scientific_topic
end

class ScientificTopic < ActiveRecord::Base; end

class ConvertScientificTopicLinksIdToUri < ActiveRecord::Migration[4.2]
  def up
    add_column :scientific_topic_links, :term_uri, :string
    add_index :scientific_topic_links, :term_uri

    puts 'Converting scientific topic link IDs to URIs'
    ScientificTopicLink.transaction do
      ScientificTopicLink.all.each do |l|
        topic = l.scientific_topic
        l.update_column(:term_uri, topic.class_id) if topic && topic.class_id
        print '.'
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
