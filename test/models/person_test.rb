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
end
