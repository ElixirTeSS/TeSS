# frozen_string_literal: true

class ScientificTopic < ActiveRecord::Base; end

class FixBrokenScientificTopics < ActiveRecord::Migration[4.2]
  # Some scientific topics' class IDs were broken by #308, this fixes them
  def up
    ScientificTopic.transaction do
      ScientificTopic.all.each do |st|
        next unless st.class_id.blank? || !st.class_id.start_with?('http://edamontology.org')

        puts "Fixing scientific topic #{st.id}"
        st.class_id = "http://edamontology.org/#{st.prefix_iri}"
        st.save
      end
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration, "Can't re-break the ScientificTopics!"
  end
end
