# frozen_string_literal: true

class CurationMailer < ApplicationMailer
  include ActionView::Helpers::TextHelper

  def user_requires_approval(user)
    @user = user
    @resources = user.reload.created_resources
    subject = "#{TeSS::Config.site['title_short']} user \"#{user.name}\" requires approval"
    mail(subject:, to: User.with_role('admin').map(&:email)) do |format|
      format.html
      format.text
    end
  end

  def source_requires_approval(source, user)
    @user = user
    @source = source
    subject = "#{TeSS::Config.site['title_short']} source \"#{@source.title}\" requires approval"
    space = @source.space || Space.default
    mail(subject:, to: space.administrators.map(&:email)) do |format|
      format.html
      format.text
    end
  end

  def events_require_approval(provider, cut_off_time)
    @provider = provider
    return unless @provider.content_curation_email.present?

    # @events = @provider.events.where { |e| e.lmm_processed > cut_off_time }
    @events = @provider.events.filter { |e| e.created_at > cut_off_time }
    subject = t('mailer.events_require_approval.subject')
    mail(subject:, to: @provider.content_curation_email) do |format|
      format.html
      format.text
    end
  end

  def materials_require_approval(provider, cut_off_time)
    @provider = provider
    return unless @provider.content_curation_email.present?

    @materials = @provider.materials.filter { |e| e.created_at > cut_off_time }
    subject = t('mailer.materials_require_approval.subject')
    mail(subject:, to: @provider.content_curation_email) do |format|
      format.html
      format.text
    end
  end

  def check_broken_scrapers(user, cut_off_time)
    return unless user.check_broken_scrapers

    source_names = TeSS::Config.ingestion[:sources].filter { |s| s[:enabled] }.map { |s| s[:provider] }.uniq
    source_names += Source.includes(:content_provider).enabled.approved.map{ |s| s.content_provider.title}
    @providers = ContentProvider
                  .left_joins(%i[events materials])
                  .where(title: source_names)
                  .where('events.updated_at < ?', cut_off_time)
                  .where('materials.updated_at < ?', cut_off_time)
                  .distinct
    subject = t('mailer.check_broken_scrapers.subject')
    mail(subject:, to: user.email) do |format|
      format.html
      format.text
    end
  end
end
