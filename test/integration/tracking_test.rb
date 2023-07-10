require 'test_helper'

class TrackingTest < ActionDispatch::IntegrationTest
  test 'Does not automatically track visits' do
    assert_no_difference('Ahoy::Visit.count') do
      get '/'
    end
  end

  test 'link tracking' do
    event = events(:one)
    material = materials(:good_material)
    trainer = profiles(:trainer_one_profile)

    get event_path(event)

    assert_select 'a.btn', text: 'View event' do
      assert_select '[data-trackable]'
      assert_select '[data-trackable-id=?]', event.id.to_s
      assert_select '[data-trackable-type=?]', 'Event'
    end

    get material_path(material)

    assert_select 'a.btn', text: 'View material' do
      assert_select '[data-trackable]'
      assert_select '[data-trackable-id=?]', material.id.to_s
      assert_select '[data-trackable-type=?]', 'Material'
    end

    get trainer_path(trainer)

    assert_select 'a[href=?]', trainer.orcid do
      assert_select '[data-trackable]'
      assert_select '[data-trackable-id]', count: 0
    end
    assert_select 'a[href=?]', trainer.website do
      assert_select '[data-trackable]'
      assert_select '[data-trackable-id]', count: 0
    end
  end
end
