require 'test_helper'

class PersonTest < ActiveSupport::TestCase
  test 'should create person with full_name' do
    person = Person.create(full_name: 'John Doe')
    assert person.valid?
    assert_equal 'John Doe', person.display_name
  end

  test 'should create person with given and family name' do
    person = Person.create(given_name: 'John', family_name: 'Doe')
    assert person.valid?
    assert_equal 'John Doe', person.display_name
  end

  test 'should require either full_name or both given and family name' do
    person = Person.new
    refute person.valid?
    assert_includes person.errors[:base], "Either full_name or both given_name and family_name must be present"
  end

  test 'should allow optional orcid' do
    person = Person.create(full_name: 'John Doe', orcid: '0000-0001-2345-6789')
    assert person.valid?
    assert_equal '0000-0001-2345-6789', person.orcid
  end

  test 'display_name should return full_name if present' do
    person = Person.new(full_name: 'Dr. Jane Marie Smith', given_name: 'Jane', family_name: 'Smith')
    assert_equal 'Dr. Jane Marie Smith', person.display_name
  end

  test 'display_name should construct from given and family name if full_name is blank' do
    person = Person.new(given_name: 'Jane', family_name: 'Smith')
    assert_equal 'Jane Smith', person.display_name
  end

  test 'should have person_links' do
    person = people(:horace)
    assert_respond_to person, :person_links
  end

  test 'should allow optional profile association' do
    person = Person.create(full_name: 'John Doe')
    assert person.valid?
    assert_nil person.profile
  end

  test 'should automatically link to profile by orcid on save' do
    profile = profiles(:trainer_one_profile)
    # The trainer_one_profile has orcid: https://orcid.org/0000-0002-1825-0097
    person = Person.create(full_name: 'Josiah Carberry', orcid: 'https://orcid.org/0000-0002-1825-0097')
    assert person.valid?
    assert_equal profile, person.profile
  end

  test 'should automatically link to profile using short orcid format' do
    profile = profiles(:trainer_one_profile)
    # The trainer_one_profile has orcid: https://orcid.org/0000-0002-1825-0097
    person = Person.create(full_name: 'Josiah Carberry', orcid: '0000-0002-1825-0097')
    assert person.valid?
    assert_equal profile, person.profile
  end

  test 'should not link to profile if no matching orcid' do
    person = Person.create(full_name: 'John Doe', orcid: '0000-0001-9999-9999')
    assert person.valid?
    assert_nil person.profile
  end

  test 'should should break profile link if orcid removed' do
    profile = profiles(:trainer_one_profile)
    # The trainer_one_profile has orcid: https://orcid.org/0000-0002-1825-0097
    person = Person.create(full_name: 'Josiah Carberry', orcid: '0000-0002-1825-0097', profile: profile)
    assert person.valid?
    assert_equal profile, person.profile

    person.update(orcid: nil)
    assert_nil person.profile
  end


  test 'should not override existing profile link' do
    profile1 = profiles(:trainer_one_profile)
    profile2 = profiles(:admin_trainer_profile)

    # First, manually set a profile
    person = Person.create(full_name: 'John Doe', profile: profile2)
    assert_equal profile2, person.profile

    # Even if we update the ORCID to match profile1, it should keep profile2
    refute person.update(orcid: '0000-0002-1825-0097')
    assert_equal profile2, person.profile
  end
end
