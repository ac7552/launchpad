class ParentMailer < ApplicationMailer
  def portal_invite(guardianship)
    @guardianship = guardianship
    @operator = Launchpad::Privacy.operator
    @link = join_url(guardianship.token)
    mail to: guardianship.email, subject: "See #{guardianship.student.first_name}'s work on Launchpad"
  end

  def consent_request(consent)
    @consent = consent
    @operator = Launchpad::Privacy.operator
    @link = parent_consent_url(consent.token)
    mail to: consent.parent_email, subject: "Permission for #{consent.student.first_name} to use Launchpad"
  end
end
