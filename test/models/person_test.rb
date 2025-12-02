require 'test_helper'

class PersonTest < ActiveSupport::TestCase
  test 'should create person with first and last name' do
    person = Person.create(first_name: 'John', last_name: 'Doe')
    assert person.valid?
    assert_equal 'John Doe', person.full_name
  end

  test 'should require first name' do
    person = Person.new(last_name: 'Doe')
    refute person.valid?
    assert_includes person.errors[:first_name], "can't be blank"
  end

  test 'should require last name' do
    person = Person.new(first_name: 'John')
    refute person.valid?
    assert_includes person.errors[:last_name], "can't be blank"
  end

  test 'should allow optional orcid' do
    person = Person.create(first_name: 'John', last_name: 'Doe', orcid: '0000-0001-2345-6789')
    assert person.valid?
    assert_equal '0000-0001-2345-6789', person.orcid
  end

  test 'full_name should concatenate first and last name' do
    person = Person.new(first_name: 'Jane', last_name: 'Smith')
    assert_equal 'Jane Smith', person.full_name
  end

  test 'should have person_links' do
    person = people(:horace)
    assert_respond_to person, :person_links
  end
end
