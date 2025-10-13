require 'test_helper'

class UsersHelperTest < ActionView::TestCase
  include ApplicationHelper

  test 'displays authenticated orcid link' do
    profile = profiles(:trainer_one_profile)
    l = orcid_link(profile)
    assert_includes l, 'ORCID-iD_icon_vector.svg'
    assert_not_includes l, 'Unauthenticated'
  end

  test 'displays unauthenticated orcid link' do
    profile = profiles(:trainer_two_profile)
    l = orcid_link(profile)
    assert_includes l, 'ORCID-iD_icon_unauth_vector.svg'
    assert_includes l, 'Unauthenticated'
  end

end
