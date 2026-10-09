module Teach
  class ProjectsController < BaseController
    def show
      @project = Project.where(student_id: students.select(:id)).find(params[:id])
      @versions = @project.versions.reverse
      @interactions = @project.ai_interactions
      @open_review = @project.open_review
      @returned = @project.reviews.returned.includes(:reviewer).order(returned_at: :desc)
    end
  end
end
