require 'test_helper'

class SourceFilterTest < ActiveSupport::TestCase
  # All filter definitions are tested as part of the ingestor_test ingestors unit test.

  test 'string matching must be case insensitive' do
    [
      'does_match',
      'DOES_MATCH',
      'DOES_match'
    ].each do | t |
      assert(source_filters(:source_filter_title).match(OpenStruct.new({'title': t})), "failed matching: #{t}")
    end

    refute(source_filters(:source_filter_title).match(OpenStruct.new({'title': 'does_not_match'})))
  end

  test 'prefix string matching must be case insensitive' do
    [
      'does_match suffix',
      'DOES_MATCH SUFFIX',
      'DOES_match suFFix'
    ].each do | u |
      assert(source_filters(:source_filter_url_prefix).match(OpenStruct.new({'url': u})), "failed matching: #{u}")
    end

    refute(source_filters(:source_filter_url_prefix).match(OpenStruct.new({'url': 'not_a_match'})))
  end

  test 'contains string matching must be case insensitive' do
    [
      'prefix does_match suffix',
      'PREFIX DOES_MATCH SUFFIX',
      'PREFIX DOES_match suffix'
    ].each do | t |
      assert(source_filters(:source_filter_title_contains).match(OpenStruct.new({'title': t})), "failed matching: #{t}")
    end

    refute(source_filters(:source_filter_title_contains).match(OpenStruct.new({'title': 'not_a_match'})))
  end

  test 'array string matching must be case insensitive' do
    [
      'does_match',
      'DOES_MATCH',
      'DOES_match'
    ].each do | k |
      assert(source_filters(:source_filter_keyword).match(OpenStruct.new({'keywords': ['does_not_match', k]})), "failed matching: #{k}")
    end

    refute(source_filters(:source_filter_keyword).match(OpenStruct.new({'keywords': []})))
  end

  test 'source filter must have filter_property property' do
    assert(source_filters(:source_filter_keyword).filter_property == 'keywords')
    assert(source_filters(:source_filter_title).filter_property == 'title')
  end

  test 'source filter must handle nil and empty values' do
    assert(source_filters(:source_filter_empty_title).match(OpenStruct.new({'title': ''})))
    assert(source_filters(:source_filter_empty_title).match(OpenStruct.new({'title': nil})))
    refute(source_filters(:source_filter_empty_title).match(OpenStruct.new({'title': 'a'})))
    
    assert(source_filters(:source_filter_no_title).match(OpenStruct.new({'title': ''})))
    assert(source_filters(:source_filter_no_title).match(OpenStruct.new({'title': nil})))
    refute(source_filters(:source_filter_no_title).match(OpenStruct.new({'title': 'a'})))
  end
end
