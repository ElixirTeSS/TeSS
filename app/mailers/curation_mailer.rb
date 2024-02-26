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

  def events_require_approval(provider)
    @provider = provider
    # @events = @provider.events.where { |e| e.lmm_processed > Time.zone.now - 1.week }
    @events = @provider.events.filter { |e| e.created_at > Time.zone.now - 1.week }
    return if @events.count.zero? || @provider.contact.nil?

    subject = "#{TeSS::Config.site['title_short']} events require approval"
    mail(subject:, to: @provider.contact) do |format|
      format.html
      format.text
    end
  end
end
