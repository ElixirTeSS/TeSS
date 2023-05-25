# frozen_string_literal: true

class ConvertEventTypesToControlledVocabulary < ActiveRecord::Migration[4.2]
  MAPPING = {
    'event' => '',
    'course' => 'workshops_and_courses',
    'meeting' => 'meetings_and_conferences'
  }.freeze

  def up
    Rails.logger.debug 'Converting event_type to controlled vocab'
    Event.transaction do
      Event.all.each do |e|
        types = e.event_type
        new_types = types.map { |type| MAPPING[type] || type }.compact_blank
        new_types = new_types.select { |type| EventTypeDictionary.instance.lookup(type) }.compact
        if types != new_types
          e.update_column(:event_type, new_types)
          Rails.logger.debug '.'
        end
      end
    end
    puts
  end

  def down
    Rails.logger.debug 'Reverting event_type to old values'
    Event.transaction do
      Event.all.each do |e|
        types = e.event_type                    # v  Note the invert!
        new_types = types.map { |type| MAPPING.invert[type] || type }.compact_blank.compact
        if types != new_types
          e.update_column(:event_type, new_types)
          Rails.logger.debug '.'
        end
      end
    end
    puts
  end
end
