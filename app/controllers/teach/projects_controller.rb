module Teach
  class ProjectsController < BaseController
    def show
      @project = Project.where(student_id: students.select(:id)).find(params[:id])
      @versions = @project.versions.reverse
      @interactions = @project.ai_interactions
    end
  end
end
