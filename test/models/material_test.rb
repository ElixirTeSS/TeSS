require 'test_helper'

class MaterialTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end

  test "material attributes title, short_decription and url should not be empty" do
    material = Material.new
    assert material.invalid?
    assert material.errors[:title].any?
    assert material.errors[:short_description].any?
    assert material.errors[:url].any?
  end

  test "url must be in correct format" do
    materials
  end
end
