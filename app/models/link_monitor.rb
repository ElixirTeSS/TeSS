class LinkMonitor < ApplicationRecord
  belongs_to :link_checkable, polymorphic: true, foreign_key: :lcheck_id, foreign_type: :lcheck_type
  before_create :set_initial_date
  after_commit :reindex_resource, on: :update

  FAILURE_THRESHOLD = 4

  def set_initial_date
    self.failed_at ||= Time.now
    self.last_failed_at ||= Time.now
    self.fail_count ||= 1
  end

  def failure(code = nil) # `fail` is a Ruby Kernel method
    self.code = code if code
    self.failed_at ||= Time.now
    self.last_failed_at = Time.now
    self.fail_count += 1
  end

  def fail!(code = nil)
    failure(code)
    save!
  end

  def success
    self.code = 200
    self.failed_at = nil
    self.last_failed_at = nil
    self.fail_count = 0
  end

  def success!
    success
    save!
  end

  def failing?
    fail_count >= FAILURE_THRESHOLD
  end

  def status_changed?
    prev_count = fail_count_previously_was || 0
    prev_count >= FAILURE_THRESHOLD && fail_count == 0 ||
      prev_count < FAILURE_THRESHOLD && failing?
  end

  private

  def reindex_resource
    return unless TeSS::Config.solr_enabled
    return unless status_changed?
    link_checkable.solr_index
  end
end
