require 'test_helper'

class MaterialTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end


  setup do
    @user = User.new(:username=>'bobo',
                  :email=>'exampl@example.com',
                  :role => Role.first,
                  :password => SecureRandom.base64
    )
    @user.save!
    @material = Material.new(:title => 'title', :short_description => 'short desc', :url => 'http://goog.e.com', :user => @user)
    @material.save!
  end

  test 'should reassign owner when user deleted' do
    material_id = @material.id
    owner = @material.user
    assert_not_equal 'default_user', owner.role.name
    owner.destroy
    #Reload the material
    material = Material.find_by_id(material_id)
    assert_equal 'default_user', material.user.role.name
  end

=begin
  test 'should save good new material' do
    material = new_material()
    assert material.valid?
    assert materials.errors.empty?
  end

  test 'url should not be empty' do
    material = new_material('')
    assert material.invalid?
    assert material.errors[:url].any?
  end

  def new_material(title=materials(:good_material).title,
                   short_description=materials(:good_material).short_description,
                   url=materials(:good_material).url)
    Material.new(title: title,
        short_description: short_description,
        url: url)
  end

  test "url must be in correct format" do

    material =  new_material(materials(:bad_material).url)
    assert material.invalid?
    assert material.errors[:url].any?, "#{material.url} should not be valid"

    material2 =  new_material(materials(:good_material).url)
    assert material2.valid?, "#{material.url} should be valid"
  end
=end

end
