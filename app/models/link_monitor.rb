# frozen_string_literal: true

class LinkMonitor < ApplicationRecord
  belongs_to :link_checkable, polymorphic: true, foreign_key: :lcheck_id, foreign_type: :lcheck_type
  before_create :set_initial_date

  FAILURE_THRESHOLD = 4

  def set_initial_date
    self.failed_at ||= Time.zone.now
    self.last_failed_at ||= Time.zone.now
    self.fail_count ||= 1
  end

  # `fail` is a Ruby Kernel method
  def failure(code = nil)
    self.code = code if code
    self.failed_at ||= Time.zone.now
    self.last_failed_at = Time.zone.now
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
end
