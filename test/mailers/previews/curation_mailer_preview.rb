# frozen_string_literal: true

# Preview all emails at http://localhost:3000/rails/mailers/curation_mailer
class CurationMailerPreview < ActionMailer::Preview
  def unverified_user_needs_approval
    user = User.with_role('unverified_user').unbanned.last
    CurationMailer.user_requires_approval(user)
  end

  def source_needs_approval
    source = Source.first
    CurationMailer.source_requires_approval(source, source.user)
  end

  def events_need_approval
    provider = ContentProvider.first
    CurationMailer.events_require_approval(provider, Time.zone.now - 1.week)
  end

  def materials_need_approval
    provider = ContentProvider.first
    CurationMailer.materials_require_approval(provider, Time.zone.now - 1.week)
  end

  def check_broken_scrapers
    user = User.with_role('admin').first
    CurationMailer.check_broken_scrapers(user, Time.zone.now - 1.week)
  end
end
