module Teach
  class ProjectReviewsController < BaseController
    def update
      review = ProjectReview.joins(:project).where(projects: { student_id: students.select(:id) }).find(params[:id])
      attrs = params.require(:project_review).permit(:coding, :problem_solving, :ownership, :feedback)
      scores = attrs.slice(:coding, :problem_solving, :ownership).to_h.transform_values(&:to_i)
      review.return!(by: current_user, scores:, feedback: attrs[:feedback].to_s.strip)
      redirect_to teach_grading_index_path, notice: "Returned to #{review.student.first_name}."
    rescue ActiveRecord::RecordInvalid
      redirect_to teach_project_path(review.project, anchor: "grade"), alert: "Score all three areas and write some feedback."
    end
  end
end
