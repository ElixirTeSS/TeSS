class LinkMonitor < ActiveRecord::Base
  belongs_to :link_checkable, polymorphic: true, foreign_key: :lcheck_id, foreign_type: :lcheck_type
  before_create :set_initial_date

  def set_initial_date
    self.failed_at = Time.now
    self.last_failed_at = Time.now
    self.fail_count = 1
  end

  def failure(code = nil) # `fail` is a Ruby Kernel method
    if code
      self.code = code
    end
    self.last_failed_at = Time.now
    if self.failed_at.nil?
      self.failed_at = Time.now
    end
    self.fail_count += 1
  end

  def fail!(code = nil)
    failure(code)
    save!
  end

  def success
    self.failed_at = nil
    self.last_failed_at = nil
    self.code = 200
  end

  def success!
    success
    save!
  end

  # Using Time.diff below to get the useful output, perhaps to
  # show to the user.
  def failing?
    if failed_at.nil? || last_failed_at.nil?
      return false
    end
    diff = Time.diff(last_failed_at, failed_at, '%d')
    return true if diff[:diff].to_i >= 4
    false
  end

  def failed_since?
    if failed_at.nil? || last_failed_at.nil?
      return { diff: 'Still working!' }
    end
    Time.diff(last_failed_at, failed_at)
  end
end
