module Teach
  class GuardianshipsController < BaseController
    # Invite a parent to the parent portal (and the family message thread).
    def create
      student = students.find(params[:student_id])
      guardianship = student.guardianships.new(params.require(:guardianship).permit(:name, :email))
      if guardianship.save
        ParentMailer.portal_invite(guardianship).deliver_later
        redirect_to teach_student_path(student, anchor: "family"), notice: "Invite sent to #{guardianship.email}."
      else
        redirect_to teach_student_path(student, anchor: "family"), alert: guardianship.errors.full_messages.to_sentence
      end
    end
  end
end
