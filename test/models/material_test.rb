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

  def new_material(material_url)
    Material.new(title: materials(:good_material).title,
        short_description: materials(:good_material).short_description,
        url: material_url)
  end

  test "url must be in correct format" do

    material =  new_material(materials(:bad_material).url)
    assert material.invalid?
    assert material.errors[:url].any?, "#{material.url} should not be valid"

    material2 =  new_material(materials(:good_material).url)
    assert material2.valid?, "#{material.url} should be valid"
  end

end
