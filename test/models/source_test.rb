require 'test_helper'

class SourceTest < ActiveSupport::TestCase

  setup do
    @user = users :scraper_user
    assert_not_nil @user
    @time_format = '%H:%M on %A, %d %B %Y (UTC)'
  end

  test 'scraper user can update source' do
    source = sources :first_source
    refute source.nil?
    source_id = source.id
    refute source_id.nil?

    # check run details not set
    refute source.url.nil?, "source url is nil"
    refute source.content_provider.nil?, "source content_provider is nil"
    assert source.finished_at.nil?,  "Pre-update: source finished_at is not nil"

    # update run details
    finished = Time.now
    source.finished_at = finished
    source.records_read = 100
    source.records_written = 95
    source.resources_added = 12
    source.resources_updated = 83
    source.resources_rejected = 5
    output = "### Sample Output\nThis is text.\n-  records read[100]\n- records written[83]"
    source.log = output

    # check update
    assert source.valid?
    assert source.save
    assert_equal 0, source.errors.count

    # check updated details
    updated = Source.find(source_id)
    refute updated.nil?, 'updated source is nil'
    assert_equal output, updated.log, 'updated log not matched'
    refute updated.finished_at.nil?, 'updated finished_at is nil'
    assert_equal finished.strftime(@time_format),
                 updated.finished_at.strftime(@time_format),
                 'updated finished_at not matched'
    assert_equal 100, source.records_read, 'updated records read not matched'
  end


end