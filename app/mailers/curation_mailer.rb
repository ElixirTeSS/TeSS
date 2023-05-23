# frozen_string_literal: true

class CurationMailer < ApplicationMailer
  include ActionView::Helpers::TextHelper

  def user_requires_approval(user)
    @user = user
    @resources = user.reload.created_resources
    subject = "#{TeSS::Config.site['title_short']} user \"#{user.name}\" requires approval"
    mail(subject: subject, to: User.with_role('admin').map(&:email)) do |format|
      format.html
      format.text
    end
  end

  def source_requires_approval(source, user)
    @user = user
    @source = source
    subject = "#{TeSS::Config.site['title_short']} source \"#{@source.title}\" requires approval"
    mail(subject: subject, to: User.with_role('admin').map(&:email)) do |format|
      format.html
      format.text
    end
  end
end
