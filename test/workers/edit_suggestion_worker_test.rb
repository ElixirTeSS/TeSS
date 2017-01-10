require 'test_helper'
require 'sidekiq/testing'

class EditSuggestionWorkerTest < ActiveSupport::TestCase

  test 'Start a background job' do
    assert_equal EditSuggestionWorker.jobs.size, 0
    material = materials(:biojs)
    EditSuggestionWorker.perform_async(material.id)
    assert_equal EditSuggestionWorker.jobs.size, 1
  end

end
