require 'test_helper'
require 'minitest/autorun'

class LlmServiceTest < ActiveSupport::TestCase
  def setup
    mock_llm_requests
  end

  test 'service_hash_contains_all_subclasses' do
    hash_set = (Llm.service_hash.values + [Llm::Service]).map { |c| c.name.split('::').last.to_sym }.to_set
    classes_set = Llm.constants.filter { |c| Llm.const_get(c).is_a?(Class) }.to_set
    assert hash_set == classes_set
  end

  test 'no_post_processing unless model provided' do
    with_settings({ llm_scraper: { model: 'willma' } }) do
      mock = Minitest::Mock.new
      Event.stub :not_finished, mock do
        mock.expect :needs_processing, [], [String]
        Llm.post_processing_task
      end
      mock.verify
    end

    with_settings({ llm_scraper: { model: nil } }) do
      mock = Minitest::Mock.new
      Event.stub :not_finished, mock do
        mock.expect :needs_processing, []
        Llm.post_processing_task
      end
      assert_raises(MockExpectationError) { mock.verify }
    end
  end

  test 'NotImplementedError on parent class initialization' do
    assert_raises(NotImplementedError) { Llm::Service.new }
  end

  test 'check event filtering in post_processing' do
    u = users(:scraper_user)
    event1 = Event.create!(title: 'needs_processing', start: Time.zone.now - 5.hours, end: Time.zone.now + 5.hours, url: 'https://www.google.com#1', user_id: u.id)
    event1.llm_interaction = llm_interactions(:needs_processing)
    event1.save!
    event2 = Event.create!(title: 'different_prompt', start: Time.zone.now - 5.hours, end: Time.zone.now + 5.hours, url: 'https://www.google.com#2', user_id: u.id)
    event2.llm_interaction = llm_interactions(:different_prompt)
    event2.save!
    event3 = Event.create!(title: 'finished', start: Time.zone.now - 5.hours, end: Time.zone.now - 4.hours, url: 'https://www.google.com#3', user_id: u.id)
    event3.llm_interaction = llm_interactions(:scrape)
    event3.save!
    result = Llm.filtered_event_list(event1.llm_interaction.prompt)
    assert result.map(&:title) == %w[needs_processing different_prompt]
  end

  test 'test willma scrape' do
    with_settings({ llm_scraper: { model: 'willma', model_version: 'Zephyr 7B' } }) do
      result = Llm::WillmaService.new.scrape('my_html')
      assert result['title'] = 'my_title'
      assert result['venue'] = 'my_venue'
      assert result['description'] = 'my_description'
    end
  end

  test 'test gpt scrape' do
    run_res = '{
      "title":"my_title",
      "start":"2024-07-03T12:30:00+02:00",
      "end":"2024-07-03T19:00:00+02:00",
      "venue":"my_venue",
      "description":"my_description",
    }'.gsub(/\n/, '')
    mock_client = Minitest::Mock.new
    mock_client.expect(:chat, { 'choices' => { 0 => { 'message' => { 'content' => run_res } } } }, parameters: Object)
    # run task
    OpenAI::Client.stub(:new, mock_client) do
      with_settings({ llm_scraper: { model: 'chatgpt', model_version: 'GPT-3.5' } }) do
        result = Llm::ChatgptService.new.scrape('my_html')
        assert result['title'] = 'my_title'
        assert result['venue'] = 'my_venue'
        assert result['description'] = 'my_description'
      end
    end
  end
end
