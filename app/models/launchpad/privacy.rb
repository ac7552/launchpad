# One place for Launchpad's privacy promises. The privacy page, the parent notice, and the
# retention job all read from here, so what we publish is what the code does.
module Launchpad
  module Privacy
    # Bump when the parent notice changes in a way parents should re-consent to.
    NOTICE_VERSION = "2026-10-05".freeze

    # Unanswered consent requests: the child's account (name, username) is deleted after this.
    UNCONSENTED_DAYS = 14
    # Accounts with no activity for this long are deleted with all their projects.
    INACTIVE_DAYS = 365
    # AI coach logs (hints, questions, answers) are deleted after this.
    AI_LOG_DAYS = 365

    AI_PROVIDER = "Anthropic (the company that makes the Claude AI model)".freeze

    VERIFICATION_METHODS = {
      "signed_form_in_person" => "Signed consent form, handed in person",
      "signed_form_scan" => "Signed consent form, sent as a scan or photo",
      "video_call" => "Video call with the parent, ID shown"
    }.freeze

    # Who runs the program. Set these before real families use Launchpad.
    def self.operator
      {
        name: ENV.fetch("LAUNCHPAD_OPERATOR_NAME", "[Your business name]"),
        address: ENV.fetch("LAUNCHPAD_OPERATOR_ADDRESS", "[Mailing address]"),
        email: ENV.fetch("LAUNCHPAD_OPERATOR_EMAIL", "[Privacy contact email]"),
        phone: ENV.fetch("LAUNCHPAD_OPERATOR_PHONE", "[Phone number]")
      }
    end

    def self.operator_configured? = operator.values.none? { |v| v.start_with?("[") }
  end
end
