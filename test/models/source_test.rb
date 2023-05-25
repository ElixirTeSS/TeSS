# frozen_string_literal: true

require 'test_helper'

class SourceTest < ActiveSupport::TestCase
  setup do
    @user = users :scraper_user

    refute_nil @user
  end

  test 'scraper user can update source' do
    source = sources :first_source

    refute_nil source
    source_id = source.id

    refute_nil source_id

    # check run details not set
    refute_nil source.url, 'source url is nil'
    refute_nil source.content_provider, 'source content_provider is nil'
    assert_nil source.finished_at, 'Pre-update: source finished_at is not nil'

    # update run details
    finished = Time.zone.now
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

    refute_nil updated, 'updated source is nil'
    assert_equal output, updated.log, 'updated log not matched'
    refute_nil updated.finished_at, 'updated finished_at is nil'
    assert_in_delta finished, updated.finished_at, 0.001, 'updated finished_at not matched'
    assert_equal 100, source.records_read, 'updated records read not matched'
  end

  test 'can get enabled sources' do
    sources = Source.enabled

    assert_includes sources, sources(:enabled_source)
    assert_not_includes sources, sources(:first_source)
    assert_not_includes sources, sources(:second_source)
  end

  test 'can get approved sources' do
    sources = Source.approved

    assert_includes sources, sources(:first_source)
    assert_not_includes sources, sources(:unapproved_source)
    assert_not_includes sources, sources(:approval_requested_source)
  end

  test 'can get approval-requested sources' do
    sources = Source.approval_requested

    assert_not_includes sources, sources(:first_source)
    assert_not_includes sources, sources(:unapproved_source)
    assert_includes sources, sources(:approval_requested_source)
  end

  test 'source approval status is set to not_approved by default if regular user' do
    assert TeSS::Config.feature['user_source_creation']
    User.current_user = users(:regular_user)
    source = Source.new(content_provider: content_providers(:portal_provider),
                        url: 'https://website.org',
                        method: 'bioschemas',
                        user: User.current_user)

    assert source.save
    assert_equal :not_approved, source.approval_status
  end

  test 'source approval status is set to approved by default if admin' do
    assert TeSS::Config.feature['user_source_creation']
    User.current_user = users(:admin)
    source = Source.new(content_provider: content_providers(:portal_provider),
                        url: 'https://website.org',
                        method: 'bioschemas',
                        user: User.current_user)

    assert source.save
    assert_equal :approved, source.approval_status
  end

  test 'source approval status is set to approved by default if source_approval disabled' do
    with_settings(feature: { user_source_creation: false }) do
      refute TeSS::Config.feature['user_source_creation']
      User.current_user = users(:regular_user)
      source = Source.new(content_provider: content_providers(:portal_provider),
                          url: 'https://website.org',
                          method: 'bioschemas',
                          user: User.current_user)

      assert source.save
      assert_equal :approved, source.approval_status
    end
  end

  test 'changes to approval status are logged' do
    source = sources(:unapproved_source)
    admin = users(:admin)
    User.current_user = admin

    assert_equal :not_approved, source.approval_status

    assert_difference('PublicActivity::Activity.count', 1) do # approval status change
      assert source.update(approval_status: 'approved')
    end

    activity = source.activities.last

    assert_equal admin, activity.owner
    assert_equal source, activity.trackable
    assert_equal 'source.approval_status_changed', activity.key
    assert_equal 'not_approved', activity.parameters[:old]
    assert_equal 'approved', activity.parameters[:new]
  end

  test 'updating essential source fields resets the approval status' do
    source = sources(:first_source)
    User.current_user = source.user

    assert_equal :approved, source.approval_status

    assert_difference('PublicActivity::Activity.count', 1) do
      assert source.update(url: 'https://new-url.com')
    end

    assert_equal :not_approved, source.reload.approval_status
  end

  test 'updating essential source fields does not reset the approval status for admin' do
    source = sources(:first_source)
    admin = users(:admin)
    User.current_user = admin

    assert_equal :approved, source.approval_status

    assert_difference('PublicActivity::Activity.count', 1) do
      assert source.update(url: 'https://new-url.com')
    end

    assert_equal :approved, source.reload.approval_status
  end

  test 'updating non-essential source fields does not reset the approval status' do
    source = sources(:first_source)
    User.current_user = source.user

    assert_equal :approved, source.approval_status

    assert_difference('PublicActivity::Activity.count', 1) do
      assert source.update(enabled: true)
    end

    assert_equal :approved, source.reload.approval_status
  end

  test 'status convenience methods' do
    assert sources(:first_source).approved?
    refute sources(:first_source).approval_requested?
    refute sources(:first_source).not_approved?

    refute sources(:approval_requested_source).approved?
    assert sources(:approval_requested_source).approval_requested?
    refute sources(:approval_requested_source).not_approved?

    refute sources(:unapproved_source).approved?
    refute sources(:unapproved_source).approval_requested?
    assert sources(:unapproved_source).not_approved?
  end

  test 'request approval' do
    user = users(:regular_user)
    User.current_user = user
    source = sources(:unapproved_source)

    refute source.approval_requested?

    assert_difference('PublicActivity::Activity.count', 1) do # approval status change
      source.request_approval
    end

    assert source.reload.approval_requested?
    activity = source.activities.last

    assert_equal user, activity.owner
    assert_equal source, activity.trackable
    assert_equal 'source.approval_status_changed', activity.key
    assert_equal 'not_approved', activity.parameters[:old]
    assert_equal 'requested', activity.parameters[:new]
  end

  test 'validates method is allowed by user' do
    with_settings(user_ingestion_methods: ['bioschemas']) do
      user = users(:regular_user)
      User.current_user = user
      source = sources(:unapproved_source)

      assert source.valid?
      source.method = 'tess_event'

      refute source.valid?
      assert source.errors.added?(:method, :inclusion, value: 'tess_event')
    end
  end

  test 'validates method is allowed by admin' do
    with_settings(user_ingestion_methods: ['bioschemas']) do
      user = users(:admin)
      User.current_user = user
      source = sources(:unapproved_source)

      assert source.valid?
      source.method = 'tess_event'

      assert source.valid?
      assert_empty source.errors
    end
  end

  test 'logging results of ingestion does not create any activities' do
    source = sources(:first_source)
    User.current_user = source.user

    assert_no_difference('PublicActivity::Activity.count') do
      source.records_read = 3
      source.records_written = 2
      source.resources_added = 1
      source.resources_updated = 1
      source.resources_rejected = 1
      source.log = 'test'
      source.finished_at = Time.zone.now
      source.save!
    end
  end

  test 'changing source metadata does create activities' do
    source = sources(:first_source)
    User.current_user = source.user

    assert_difference('PublicActivity::Activity.count', 2) do
      source.url = 'https://icalendars.golf/calendar123.ical'
      source.method = 'ical'
      source.save!
    end
  end
end
