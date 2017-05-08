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

end
