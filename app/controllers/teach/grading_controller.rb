module Teach
  class GradingController < BaseController
    def index
      mine = ProjectReview.joins(:project).where(projects: { student_id: students.select(:id) })
      @waiting = mine.waiting.includes(project: :student)
      @returned = mine.returned.includes(:reviewer, project: :student).order(returned_at: :desc).limit(15)
    end
  end
end
