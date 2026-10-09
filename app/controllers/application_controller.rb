class ApplicationController < ActionController::Base
  include Authentication
  allow_browser versions: :modern

  helper_method :current_user
  before_action :enforce_consent, :touch_activity

  private
    def current_user = Current.session&.user

    # A parent can revoke consent at any time; that ends the child's session immediately.
    def enforce_consent
      return unless current_user && !current_user.can_sign_in?
      terminate_session
      redirect_to new_session_path, alert: "Your account is waiting for a parent's permission. Ask your teacher."
    end

    # Used by the retention policy to find inactive accounts. Written at most once an hour.
    def touch_activity
      user = current_user
      return unless user && (user.last_active_at.nil? || user.last_active_at < 1.hour.ago)
      user.update_column(:last_active_at, Time.current)
    end

    def require_student
      redirect_to root_path, alert: "That page is for students." unless current_user&.student?
    end

    def require_parent
      redirect_to root_path, alert: "That page is for parents." unless current_user&.parent?
    end

    def require_staff
      redirect_to root_path, alert: "That page is for teachers." unless current_user&.staff?
    end
end
