require 'test_helper'

class MaterialsHelperTest < ActionView::TestCase

  test "edam file loaded successfully" do
    assert_equal(edam_names_for_autocomplete.class,Array)
    assert_equal(edam_names_for_autocomplete[0].class,Hash)
    assert_not_empty(edam_names_for_autocomplete)
  end

end