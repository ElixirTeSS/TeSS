require 'test_helper'

class TrainersControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  setup do
    @user = users(:trainer_user)
    @trainer = @user.profile
  end

  test 'get all trainers' do
    get :index
    assert_response :success
    trainers = assigns(:trainers)
    assert_not_nil trainers
    assert_equal 2, trainers.size
    assert_includes trainers, users(:trainer_user).profile
  end

  test 'should show material and event in trainer page as bioschemas JSON-LD' do
    material = materials(:good_material)
    material.user_id = @user.id
    material.scientific_topic_uris = ['http://edamontology.org/topic_0654']
    material.save!

    event = events(:one)
    event.user = @user
    event.scientific_topic_uris = ['http://edamontology.org/topic_0654']
    event.save!

    get :show, params: { id: @trainer, format: :html }
    assert_response :success
    assert assigns(:trainer)

    doc = Nokogiri::HTML(response.body)
    jsonld = doc
             .css('script[type="application/ld+json"]')
             .map do |s|
               JSON.parse(s.text)
             rescue JSON::ParserError
               nil
             end
             .compact

    json_material = jsonld.find { |entry| entry['name'] == material.title }
    assert_equal material.title, json_material['name']
    assert_equal 'http://schema.org', json_material['@context']
    assert_equal 'LearningResource', json_material['@type']
    assert_equal 'https://bioschemas.org/profiles/TrainingMaterial/1.0-RELEASE', json_material['dct:conformsTo']['@id']
    assert_equal material.url, json_material['url']
    assert_equal material.scientific_topic_uris.first, json_material['about'].first['@id']

    json_event = jsonld.find { |entry| entry['name'] == event.title }
    assert_equal 'http://schema.org', json_event['@context']
    assert_equal 'Course', json_event['@type']
    assert_equal 'https://bioschemas.org/profiles/Course/1.0-RELEASE', json_event['dct:conformsTo']['@id']
    assert_equal event.title, json_event['name']
    assert_equal event.url, json_event['url']
    assert_equal event.scientific_topic_uris.first, json_event['about'].first['@id']
    external_resource = event.external_resources.first
    assert_not_nil external_resource
    assert_equal external_resource.url, json_event['mentions'].first['url']
  end
end
