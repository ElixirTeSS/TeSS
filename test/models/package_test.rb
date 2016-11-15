require 'test_helper'

class PackageTest < ActiveSupport::TestCase

  test 'visibility scope' do
    assert_not_includes Package.visible_by(nil), packages(:secret_package)
    assert_not_includes Package.visible_by(users(:another_regular_user)), packages(:secret_package)
    assert_includes Package.visible_by(users(:regular_user)), packages(:secret_package)
    assert_includes Package.visible_by(users(:admin)), packages(:secret_package)

    assert_includes Package.visible_by(nil), packages(:one)
    assert_includes Package.visible_by(users(:another_regular_user)), packages(:one)
    assert_includes Package.visible_by(users(:regular_user)), packages(:one)
    assert_includes Package.visible_by(users(:admin)), packages(:one)
  end

end
