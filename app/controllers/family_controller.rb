# The parent portal: a parent sees their own children's work, goals, and teacher feedback.
class FamilyController < ApplicationController
  before_action :require_parent
  before_action :set_child, only: %i[child project]

  def show
    @children = current_user.children.includes(:projects, :skill_checks)
    redirect_to family_child_path(@children.first) if @children.one?
  end

  def child
    @stage = @child.current_stage
    @passed = @child.skill_checks.pluck(:milestone_id).to_set
    @projects = @child.projects.includes(:reviews).order(updated_at: :desc)
    @reviews = ProjectReview.returned.joins(:project).where(projects: { student_id: @child.id }).includes(:project, :reviewer).order(returned_at: :desc).limit(5)
    @help_count = @child.help_sessions.where(created_at: 30.days.ago..).count
    @consent = @child.parent_consent
  end

  def project
    @project = @child.projects.find(params[:id])
    @reviews = @project.reviews.returned.includes(:reviewer).order(returned_at: :desc)
  end

  private
    def set_child
      @child = current_user.children.find(params[:student_id])
    end
end
