require 'test_helper'
require Rails.root.join('db/migrate/20260826101500_backfill_content_provider_field_locks')

class FieldLockTest < ActiveSupport::TestCase

  test 'can add field locks to a model' do
    event = events(:one)

    assert_empty event.locked_fields
    event.locked_fields = [:title, :description]
    assert_equal 2, event.locked_fields.length

    assert_difference('FieldLock.count', 2) do
      event.save
    end

    assert_equal [:title, :description].sort, event.locked_fields.sort
    assert event.field_locked?(:title)
    assert event.field_locked?(:description)
    refute event.field_locked?(:url)
  end

  test 'does not add duplicate field locks' do
    event = events(:one)

    event.locked_fields = [:title, :description, :description]

    assert_difference('FieldLock.count', 2) do
      event.save
    end
  end

  test 'strips aliased fields' do
    event = events(:one)

    event.locked_fields = [:title, :node_ids]

    params = { event: { title: 'Something', description: 'Something else', node_names: ['One', 'Two'] } }.with_indifferent_access
    FieldLock.strip_locked_fields(params[:event], event.locked_fields)
    assert_equal({ description: 'Something else' }.with_indifferent_access, params[:event])

    provider = content_providers(:goblet)
    provider.locked_fields = [:image]

    provider_params = {
      content_provider: {
        image: 'uploaded-file',
        image_url: 'http://example.com/new-image.png',
        title: 'Kept title'
      }
    }.with_indifferent_access
    FieldLock.strip_locked_fields(provider_params[:content_provider], provider.locked_fields)
    assert_equal({ title: 'Kept title' }.with_indifferent_access, provider_params[:content_provider])
  end

  test 'automatic field locking config supports all and per-resource values' do
    resources = [Material.new, Event.new, ContentProvider.new]
    { true => [true, true, true], false => [false, false, false], nil => [false, false, false],
      %w[materials events] => [true, true, false], %w[content_providers] => [false, false, true],
      %w[providers] => [false, false, false],
      %w[material event content_provider] => [false, false, false] }.each do |setting, expected|
      with_settings(automatic_field_locking: setting) do
        assert_equal expected, resources.map { |resource| TeSS::Config.automatic_field_locking_enabled_for?(resource) }
      end
    end
  end

  test 'can add field locks to content provider' do
    provider = content_providers(:provider_with_empty_image_url)

    assert_empty provider.locked_fields
    provider.locked_fields = [:title, :image]

    assert_difference('FieldLock.count', 2) do
      provider.save
    end

    assert_equal [:image, :title], provider.locked_fields.sort
    assert provider.field_locked?(:title)
    assert provider.field_locked?(:image)

  end

end
