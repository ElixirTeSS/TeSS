require 'test_helper'

class AuthorTest < ActiveSupport::TestCase
  test 'should create author with first and last name' do
    author = Author.create(first_name: 'John', last_name: 'Doe')
    assert author.valid?
    assert_equal 'John Doe', author.full_name
  end

  test 'should require first name' do
    author = Author.new(last_name: 'Doe')
    refute author.valid?
    assert_includes author.errors[:first_name], "can't be blank"
  end

  test 'should require last name' do
    author = Author.new(first_name: 'John')
    refute author.valid?
    assert_includes author.errors[:last_name], "can't be blank"
  end

  test 'should allow optional orcid' do
    author = Author.create(first_name: 'John', last_name: 'Doe', orcid: '0000-0001-2345-6789')
    assert author.valid?
    assert_equal '0000-0001-2345-6789', author.orcid
  end

  test 'full_name should concatenate first and last name' do
    author = Author.new(first_name: 'Jane', last_name: 'Smith')
    assert_equal 'Jane Smith', author.full_name
  end

  test 'should associate with materials' do
    author = authors(:horace)
    assert_respond_to author, :materials
  end
end
