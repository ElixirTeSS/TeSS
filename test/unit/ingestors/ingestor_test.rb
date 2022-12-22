require 'test_helper'

class IngestorTest < ActiveSupport::TestCase
  test 'convert HTML descriptions to markdown where appropriate' do
    ingestor = Ingestors::Ingestor.new

    input = "### Title\n\nAmpersands & Quotes \""
    expected = input
    assert_equal expected, ingestor.convert_description(input)

    input = "<h1>Title</h1><ul><li>Item 1</li><li>Item 2</li>"
    expected = "# Title\n\n- Item 1\n- Item 2"
    assert_equal expected, ingestor.convert_description(input)
  end
end