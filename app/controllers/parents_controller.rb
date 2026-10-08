# The parent side of COPPA consent: read the notice, give or refuse permission, and later
# review, download, or delete the child's information. Access is by the secret link in the email.
class ParentsController < ApplicationController
  allow_unauthenticated_access
  skip_before_action :enforce_consent, :touch_activity
  # Public page, but still show the nav when someone is signed in.
  before_action :resume_session
  rate_limit to: 30, within: 1.minute, with: -> { head :too_many_requests }
  before_action :set_consent

  def show
    @operator = Launchpad::Privacy.operator
  end

  def consent
    unless params[:guardian] == "1" && params[:account_consent] == "1" && params[:signature_name].to_s.strip.length >= 3
      return redirect_to parent_consent_path(@consent.token), alert: "Please confirm you're the parent or guardian, check the Launchpad box, and type your full name."
    end
    @consent.submit!(signature_name: params[:signature_name].strip.truncate(100), ai_consent: params[:ai_consent] == "1", ip: request.remote_ip)
    redirect_to parent_consent_path(@consent.token), notice: "Thank you! One last step: the program will confirm your permission with you."
  end

  def decline
    erase(reason: "parent_declined", message: "You didn't give permission, so we deleted %s's account and everything in it.")
  end

  def ai
    return redirect_to(parent_consent_path(@consent.token)) unless @consent.verified?
    on = params[:ai_consent] == "1"
    @consent.set_ai_consent!(on)
    message = on ? "Thanks! The program will confirm this with you before the AI coach turns on." : "The AI coach is off. %s will get written hints instead."
    redirect_to parent_consent_path(@consent.token), notice: format(message, @student.first_name)
  end

  def export
    send_data StudentExport.new(@student).to_json, filename: "launchpad-#{@student.first_name.parameterize}.json", type: :json
  end

  def destroy
    erase(reason: "parent_request", message: "We deleted %s's account and everything in it.")
  end

  private
    def set_consent
      @consent = ParentConsent.find_by(token: params[:token].to_s)
      return render(:gone, status: :not_found) unless @consent
      @student = @consent.student
    end

    def erase(reason:, message:)
      name = @student.first_name
      DataDeletion.erase!(@student, reason:)
      @deleted_message = format(message, name)
      render :gone
    end
end
