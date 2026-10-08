module Teach
  class StudentsController < BaseController
    def new
      @classroom = classrooms.find(params[:classroom_id])
      @student = User.new(role: "student")
    end

    # School-managed accounts: staff create students; there is no self sign-up. Students under 13
    # can't sign in until a parent consents and staff verify it.
    def create
      @classroom = classrooms.find(params[:classroom_id])
      @student = User.new(params.require(:user).permit(:name, :username, :grade, :birth_year, :password).merge(role: "student"))
      @parent = params.fetch(:parent, {}).permit(:name, :email)

      User.transaction do
        @student.save!
        @classroom.enrollments.create!(student: @student)
        if @student.consent_required?
          consent = @student.create_parent_consent!(parent_name: @parent[:name], parent_email: @parent[:email])
          ParentMailer.consent_request(consent).deliver_later
        end
      end
      notice = @student.consent_required? ? "#{@student.name} added. We emailed #{@parent[:email]} for permission." : "#{@student.name} added."
      redirect_to teach_student_path(@student), notice:
    rescue ActiveRecord::RecordInvalid => e
      # The transaction rolled back, so the student is unsaved again; show the parent errors with theirs.
      @student.errors.add(:base, "Parent or guardian: #{e.record.errors.full_messages.to_sentence.downcase}") if e.record.is_a?(ParentConsent)
      render :new, status: :unprocessable_entity
    end

    def show
      @student = students.find(params[:id])
      @stage = @student.current_stage
      @stages = Stage.ordered.includes(:milestones)
      @checks = @student.skill_checks.index_by(&:milestone_id)
      @projects = @student.projects.order(updated_at: :desc)
      @interactions = @student.ai_interactions.recent.includes(:project).limit(30)
      @consent = @student.parent_consent
    end

    def erase
      student = students.find(params[:id])
      name = student.name
      DataDeletion.erase!(student, reason: "staff_request", requested_by: current_user)
      redirect_to teach_classrooms_path, notice: "Deleted #{name}'s account and all their data."
    end
  end
end
