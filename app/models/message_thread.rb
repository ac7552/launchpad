# One shared conversation per student. The student, their linked parents, and their teachers all
# read every message: there are no private adult-to-child messages.
class MessageThread < ApplicationRecord
  belongs_to :student, class_name: "User"
  has_many :messages, -> { order(:created_at) }, dependent: :destroy
  has_many :thread_reads, dependent: :destroy

  def self.for(student) = find_or_create_by!(student:)

  def staff = User.where(id: Classroom.joins(:enrollments).where(enrollments: { student_id: student_id }).select(:teacher_id))
  def parents = User.where(id: student.guardianships.claimed.select(:parent_id))

  def participant?(user)
    return false unless user
    return user.id == student_id if user.student?
    return student.guardianships.claimed.exists?(parent_id: user.id) if user.parent?
    user.admin? || staff.exists?(user.id)
  end

  def unread_for?(user)
    return false unless last_message_at
    read = thread_reads.find_by(user:)
    read.nil? || read.last_read_at < last_message_at
  end

  def mark_read!(user)
    thread_reads.find_or_initialize_by(user:).update!(last_read_at: Time.current)
  end
end
