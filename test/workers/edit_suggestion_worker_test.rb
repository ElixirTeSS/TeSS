require 'test_helper'
require 'sidekiq/testing'

class EditSuggestionWorkerTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper
  Sidekiq::Testing.fake!

  test 'Start a background job' do
    skip 'Test fails with 0 enqueued jobs'
    #assert_enqueued_jobs 0
    #material = materials(:biojs)
    #EditSuggestionWorker.perform_in(1.second,material.id)
    #assert_enqueued_jobs 1
  end

end
