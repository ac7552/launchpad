class ParentMailer < ApplicationMailer
  def consent_request(consent)
    @consent = consent
    @operator = Launchpad::Privacy.operator
    @link = parent_consent_url(consent.token)
    mail to: consent.parent_email, subject: "Permission for #{consent.student.first_name} to use Launchpad"
  end
end
