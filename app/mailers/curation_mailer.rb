class CurationMailer < ApplicationMailer
  include ActionView::Helpers::TextHelper

  USER_APPROVAL_RECIPIENTS = User.with_role('admin')

  def user_requires_approval(user)
    @user = user
    @resources = user.reload.created_resources
    subject = "TeSS user \"#{user.name}\" requires approval"
    mail(subject: subject, to: USER_APPROVAL_RECIPIENTS.map(&:email)) do |format|
      format.html
      format.text
    end
  end
end
