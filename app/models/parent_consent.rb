# Verifiable parental consent for a student under 13 (COPPA).
#
#   requested → submitted (parent signed online) → verified (staff checked the signed form)
#   any state → declined / revoked (the child's data is deleted)
#
# The AI coach is a separate consent because it shares project data with a third party.
# Turning it on after verification needs staff verification again; turning it off is instant.
class ParentConsent < ApplicationRecord
  STATUSES = %w[requested submitted verified declined revoked].freeze

  belongs_to :student, class_name: "User"
  belongs_to :verified_by, class_name: "User", optional: true

  has_secure_token :token, length: 36

  normalizes :parent_email, with: ->(e) { e.strip.downcase }

  validates :parent_name, presence: true, length: { maximum: 100 }
  validates :parent_email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :status, inclusion: { in: STATUSES }
  validates :verification_method, inclusion: { in: Launchpad::Privacy::VERIFICATION_METHODS.keys }, allow_nil: true

  before_create { self.requested_at ||= Time.current }

  STATUSES.each { |s| define_method(:"#{s}?") { status == s } }

  scope :awaiting_staff, -> { where(status: "submitted").or(where(status: "verified", ai_consent: true, ai_verified_at: nil)) }

  def account_allowed? = verified? && account_consent?
  def ai_allowed? = account_allowed? && ai_consent? && ai_verified_at.present?
  def ai_pending? = verified? && ai_consent? && ai_verified_at.nil?
  def needs_staff? = submitted? || ai_pending?

  def deletion_deadline = (requested_at || created_at) + Launchpad::Privacy::UNCONSENTED_DAYS.days

  def submit!(signature_name:, ai_consent:, ip:)
    update!(status: "submitted", account_consent: true, ai_consent:, signature_name:,
            submitted_at: Time.current, submitted_ip: ip, notice_version: Launchpad::Privacy::NOTICE_VERSION)
  end

  def verify!(by:, method:)
    update!(status: "verified", verified_at: verified_at || Time.current, verified_by: by, verification_method: method,
            ai_verified_at: (Time.current if ai_consent?))
  end

  def set_ai_consent!(on)
    update!(ai_consent: on, ai_verified_at: nil)
  end
end
