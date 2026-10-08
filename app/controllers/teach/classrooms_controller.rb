module Teach
  class ClassroomsController < BaseController
    def index
      @classrooms = classrooms.includes(:students, :ai_policy).order(:name)
      @review_count = interactions.needs_review.count + HelpSession.where(classroom: classrooms).needs_teacher.count
    end

    def show
      @classroom = classrooms.find(params[:id])
      @policy = @classroom.policy
      @students = @classroom.students.includes(:skill_checks, :projects, :parent_consent)
      @review_count = @classroom.ai_interactions.needs_review.count + @classroom.help_sessions.needs_teacher.count
      @recent = @classroom.ai_interactions.includes(:student).recent.limit(15)
    end

    def new
      @classroom = Classroom.new
    end

    def create
      @classroom = current_user.taught_classrooms.new(params.require(:classroom).permit(:name))
      if @classroom.save
        redirect_to teach_classroom_path(@classroom), notice: "Class created."
      else
        render :new, status: :unprocessable_entity
      end
    end
  end
end
