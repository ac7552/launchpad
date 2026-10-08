class ApplicationMailer < ActionMailer::Base
  default from: -> { ENV.fetch("LAUNCHPAD_MAIL_FROM", "launchpad@example.com") }
  layout "mailer"
end
