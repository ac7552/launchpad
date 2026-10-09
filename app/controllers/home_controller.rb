class HomeController < ApplicationController
  def show
    return redirect_to(family_path) if current_user.parent?
    return redirect_to(teach_classrooms_path) if current_user.staff?

    @student = current_user
    @stage = @student.current_stage
    @passed = @student.skill_checks.pluck(:milestone_id).to_set
    @stages = Stage.ordered.includes(:milestones)
    @last_project = @student.projects.order(updated_at: :desc).first
  end
end
