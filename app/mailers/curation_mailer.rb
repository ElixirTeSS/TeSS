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
    mail(subject:, to: User.with_role('admin').map(&:email)) do |format|
      format.html
      format.text
    end
  end

  def events_require_approval(provider, cut_off_time)
    @provider = provider
    return unless @provider.event_curation_email.present?

    # @events = @provider.events.where { |e| e.lmm_processed > cut_off_time }
    @events = @provider.events.filter { |e| e.created_at > cut_off_time }
    subject = t('mailer.events_require_approval.subject', site_name: TeSS::Config.site['title_short'])
    mail(subject:, to: @provider.event_curation_email) do |format|
      format.html
      format.text
    end
  end
end
