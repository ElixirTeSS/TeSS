class ApplicationMailer < ActionMailer::Base
  default from: TeSS::Config.sender_email
  layout 'mailer'
end
