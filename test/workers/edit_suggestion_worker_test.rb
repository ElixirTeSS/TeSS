require 'test_helper'
require 'sidekiq/testing'

class EditSuggestionWorkerTest < ActiveSupport::TestCase

  test 'Get suggestions for a material' do
    material = materials(:biojs)

    assert_nil material.edit_suggestion

    Sidekiq::Testing.inline! do
      assert_difference('EditSuggestion.count', 1) do
        EditSuggestionWorker.perform_async(material.id,material.class.name)
      end
    end

    material.reload

    assert_equal 1, material.edit_suggestion.scientific_topics.count
    assert_equal 'Bioinformatics', material.edit_suggestion.scientific_topics.first.preferred_label
  end

end
