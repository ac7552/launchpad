# Enforces the published retention policy (Launchpad::Privacy). Runs daily.
class PurgeExpiredDataJob < ApplicationJob
  queue_as :default

  def perform(now: Time.current)
    expired_consent(now).each { |s| DataDeletion.erase!(s, reason: "consent_expired") }
    inactive(now).each { |s| DataDeletion.erase!(s, reason: "inactive") }

    log_cutoff = now - Launchpad::Privacy::AI_LOG_DAYS.days
    HelpSession.where(created_at: ...log_cutoff).find_each(&:destroy!)
    AiInteraction.where(created_at: ...log_cutoff).delete_all
  end

  private
    # Under-13 students whose permission wasn't given and verified within the window.
    def expired_consent(now)
      cutoff = now - Launchpad::Privacy::UNCONSENTED_DAYS.days
      User.students.includes(:parent_consent).select do |s|
        next false unless s.consent_required? && !s.parent_consent&.account_allowed?
        started = s.parent_consent&.requested_at || s.created_at
        started < cutoff
      end
    end

    def inactive(now)
      cutoff = now - Launchpad::Privacy::INACTIVE_DAYS.days
      User.students.where("COALESCE(last_active_at, created_at) < ?", cutoff)
    end
end
