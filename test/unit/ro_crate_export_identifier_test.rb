require 'test_helper'

class RoCrateExportIdentifierTest < ActiveSupport::TestCase
  test 'normalizes DOIs to https://doi.org/ URLs' do
    expected = 'https://doi.org/10.1109/SEAA.2009.59'
    ['10.1109/SEAA.2009.59',
     'doi:10.1109/SEAA.2009.59',
     'DOI:10.1109/SEAA.2009.59',
     ' doi:10.1109/SEAA.2009.59 ',
     'http://doi.org/10.1109/SEAA.2009.59',
     'https://doi.org/10.1109/SEAA.2009.59',
     'http://dx.doi.org/10.1109/SEAA.2009.59',
     'https://dx.doi.org/10.1109/SEAA.2009.59',
     'https://www.doi.org/10.1109/SEAA.2009.59'].each do |doi|
      assert_equal expected, RoCrateExport::Identifier.url(doi), doi
    end
  end

  test 'keeps other http(s) URLs' do
    assert_equal 'http://dx.doi.ac.uk/2q3093032', RoCrateExport::Identifier.url('http://dx.doi.ac.uk/2q3093032')
    assert_equal 'https://hdl.handle.net/1234/5678', RoCrateExport::Identifier.url('https://hdl.handle.net/1234/5678')
  end

  test 'rejects values that are not DOIs or URLs' do
    [nil, '', 'not really a doi.', 'doi:', '10.12/too-short-prefix', 'https://doi.org/has spaces'].each do |value|
      assert_nil RoCrateExport::Identifier.url(value), value.inspect
    end
  end
end
