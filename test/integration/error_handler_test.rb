require 'test_helper'

class ErrorHandlerTest < ActionDispatch::IntegrationTest
  ERRORS = {
    404 => /could not be found/,
    406 => /format is not available/,
    422 => /change you wanted was rejected/,
    500 => /TeSS encountered an error/,
    503 => /TeSS is temporarily down/
  }

  ERRORS.each do |code, message_matcher|
    test "should get #{code} error as html" do
      get "/#{code}", as: :html

      assert_response code
      assert_select '#error-message', text: message_matcher
    end

    test "should get #{code} error as json" do
      get "/#{code}", as: :json

      assert_response code
      assert_match message_matcher, JSON.parse(response.body).dig('error', 'message')
    end

    test "should get #{code} error as json-api" do
      get "/#{code}", headers: { 'Accept': 'application/vnd.api+json' }

      assert_response code
      assert_match message_matcher, JSON.parse(response.body).dig('error', 'message')
    end

    test "should get blank response for #{code} error as unknown format" do
      get "/#{code}", headers: { 'Accept': 'application/banana.protocol' }

      assert_response code
      assert_empty response.body
    end
  end
end
