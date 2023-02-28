require 'test_helper'

class AutocompleteManagerTest < ActiveSupport::TestCase
  test 'suggestions' do
    AutocompleteManager.stub(:suggestions_array_for, ['apple', 'application', 'aardvark', 'banana']) do
      assert_equal ['apple', 'application'], AutocompleteManager.suggestions(:keywords, 'ap')
      assert_equal ['apple'], AutocompleteManager.suggestions(:keywords, 'apple')
      assert_equal [], AutocompleteManager.suggestions(:keywords, 'plums')

      assert_equal ['apple'], AutocompleteManager.suggestions(:keywords, 'a', 1)
      assert_equal ['apple', 'application'], AutocompleteManager.suggestions(:keywords, 'a', 2)
    end
  end

  test 'file_path' do
    assert_equal Rails.root.join('lib', 'assets', 'keywords_suggestions.txt'), AutocompleteManager.file_path('keywords')
    assert_equal Rails.root.join('lib', 'assets', 'authors_suggestions.txt'), AutocompleteManager.file_path('authors')
  end

  test 'suggestions_array_for' do
    AutocompleteManager.stub(:file_path, Rails.root.join('test', 'fixtures', 'files', 'cat_suggestions.txt')) do
      assert_equal ['meow', 'feline', 'purr', 'paws'], AutocompleteManager.suggestions_array_for(:cats)
    end

    assert_equal [], AutocompleteManager.suggestions_array_for(:type_that_does_not_have_suggestions)
    refute File.exist?(AutocompleteManager.file_path(:type_that_does_not_have_suggestions))
  end
end
