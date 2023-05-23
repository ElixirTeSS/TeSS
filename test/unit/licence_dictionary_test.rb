# frozen_string_literal: true

require 'test_helper'

class LicenceDictionaryTest < ActiveSupport::TestCase
  test 'singleton' do
    dic = LicenceDictionary.instance
    assert dic.is_a?(LicenceDictionary)

    dic2 = LicenceDictionary.instance
    assert_same dic, dic2

    assert_raise NoMethodError do
      LicenceDictionary.new
    end
  end

  test 'licences dictionary exists' do
    dic = LicenceDictionary.instance
    refute_nil dic, 'licence dictionary should exist'
    refute dic.licence_names.blank?, 'licence dictionary should not be empty'
  end

  test 'licence values exist' do
    dic = LicenceDictionary.instance
    assert_includes dic.licence_abbreviations, 'Apache-2.0',
                    "'Apache-2.0' should be among the licence abbreviations"
    assert_not_includes dic.licence_abbreviations, 'licence_that_will_never_exist',
                        "'licence_that_will_never_exist' should not be among licences"
    assert_includes dic.licence_names, 'Apache License 2.0',
                    "'Apache License 2.0' should be among the licence names"
    assert_includes dic.lookup('Apache-2.0')['see_also'], 'http://www.opensource.org/licenses/Apache-2.0',
                    "'http://www.opensource.org/licenses/Apache-2.0' should be among the licence URLs"
  end
end
