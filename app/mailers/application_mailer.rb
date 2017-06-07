class ApplicationMailer < ActionMailer::Base
  default from: TeSS::Config.contact_email
  layout 'mailer'
end
