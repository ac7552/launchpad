module Teach
  class SkillChecksController < BaseController
    def create
      student = students.find(params[:student_id])
      student.skill_checks.find_or_create_by!(milestone_id: params[:milestone_id]) { |c| c.checked_by = current_user }
      redirect_to teach_student_path(student, anchor: "milestones")
    end

    def destroy
      student = students.find(params[:student_id])
      student.skill_checks.find(params[:id]).destroy!
      redirect_to teach_student_path(student, anchor: "milestones")
    end
  end
end
