class CurriculumController < ApplicationController
  def show
    @stages = Stage.ordered.includes(:milestones)
    return unless current_user.student?

    # Students see the kid path: tap any level to read about it.
    @current_stage = current_user.current_stage
    @selected = @stages.find { |s| s.key == params[:level] } || @current_stage
    @passed = current_user.skill_checks.pluck(:milestone_id).to_set
    render :kid
  end
end
