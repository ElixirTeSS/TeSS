require 'test_helper'

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

  end

end
