module Teach
  class ConsentsController < BaseController
    def index
      consents = ParentConsent.where(student_id: students.select(:id)).includes(:student)
      @to_verify = consents.awaiting_staff.order(:submitted_at)
      @waiting = consents.where(status: "requested").order(:requested_at)
    end

    # Sends (or re-sends) the permission email.
    def create
      consent = students.find(params[:student_id]).parent_consent
      ParentMailer.consent_request(consent).deliver_later
      consent.update!(requested_at: Time.current) if consent.requested?
      redirect_back_or_to teach_student_path(consent.student), notice: "Permission email sent to #{consent.parent_email}."
    end

    # Staff confirm the parent's identity and signature (the "verifiable" in verifiable parental consent).
    def verify
      consent = students.find(params[:student_id]).parent_consent
      method = params[:verification_method].to_s
      unless consent.needs_staff? && params[:attest] == "1" && Launchpad::Privacy::VERIFICATION_METHODS.key?(method)
        return redirect_back_or_to(teach_consents_path, alert: "Pick how you verified the parent and check the confirmation box.")
      end
      consent.verify!(by: current_user, method:)
      redirect_back_or_to teach_consents_path, notice: "Verified. #{consent.student.first_name} can sign in#{' and use the AI coach' if consent.ai_allowed?}."
    end
  end
end
