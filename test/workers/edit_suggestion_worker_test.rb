require 'test_helper'
require 'sidekiq/testing'

class EditSuggestionWorkerTest < ActiveSupport::TestCase

  setup do
    mock_biotools
    mock_nominatim
  end

  test 'Get suggestions for a material' do
    material = materials(:biojs)

    assert_nil material.edit_suggestion

    Sidekiq::Testing.inline! do
      assert_difference('EditSuggestion.count', 1) do
        EditSuggestionWorker.perform_async([material.id,material.class.name])
      end
    end

    material.reload

    assert_not_nil material.edit_suggestion
    assert_equal 2, material.edit_suggestion.scientific_topics.count
    assert_includes material.edit_suggestion.scientific_topics.map(&:preferred_label), 'Small molecules'
    assert_includes material.edit_suggestion.scientific_topics.map(&:preferred_label), 'Molecular dynamics'
  end

  test 'Get suggestions for an event' do
    event = events(:portal_event)

    assert_nil event.edit_suggestion

    Sidekiq::Testing.inline! do
      assert_difference('EditSuggestion.count', 1) do
        EditSuggestionWorker.perform_async([event.id,event.class.name])
      end
    end

    event.reload

    assert_not_nil event.edit_suggestion
    assert_equal 2, event.edit_suggestion.scientific_topics.count
    assert_includes event.edit_suggestion.scientific_topics.map(&:preferred_label), 'Small molecules'
    assert_includes event.edit_suggestion.scientific_topics.map(&:preferred_label), 'Molecular dynamics'
  end

  test 'Get suggestions for a workflow' do
    workflow = workflows(:two)

    assert_nil workflow.edit_suggestion

    Sidekiq::Testing.inline! do
      assert_difference('EditSuggestion.count', 1) do
        EditSuggestionWorker.perform_async([workflow.id,workflow.class.name])
      end
    end

    workflow.reload

    assert_not_nil workflow.edit_suggestion
    assert_equal 2, workflow.edit_suggestion.scientific_topics.count
    assert_includes workflow.edit_suggestion.scientific_topics.map(&:preferred_label), 'Small molecules'
    assert_includes workflow.edit_suggestion.scientific_topics.map(&:preferred_label), 'Molecular dynamics'
  end

  test "Don't get suggestions when description is blank" do
    event = events(:no_description_event)

    assert_nil event.edit_suggestion

    Sidekiq::Testing.inline! do
      assert_no_difference('EditSuggestion.count') do
        EditSuggestionWorker.perform_async([event.id,event.class.name])
      end
    end

    event.reload

    assert_nil event.edit_suggestion
  end
end
