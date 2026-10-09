module Teach
  class StudentsController < BaseController
    # The admin view of every student: tier, level, goals, permission, and work to grade.
    def index
      @classrooms = classrooms.order(:name)
      scope = students.includes(:classrooms, :skill_checks, :parent_consent, projects: :reviews).order(:grade, :name)
      scope = scope.where(enrollments: { classroom_id: params[:classroom_id] }) if params[:classroom_id].present?
      @students = scope.to_a
      @students.select! { |s| s.tier == params[:tier] } if User::TIERS.key?(params[:tier])
      @stages = Stage.ordered.includes(:milestones).index_by(&:id)
    end

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
          @student.guardianships.create!(name: @parent[:name], email: @parent[:email])
          ParentMailer.consent_request(consent).deliver_later
        end
      end
      notice = @student.consent_required? ? "#{@student.name} added. We emailed #{@parent[:email]} for permission." : "#{@student.name} added."
      redirect_to teach_student_path(@student), notice:
    rescue ActiveRecord::RecordInvalid => e
      # The transaction rolled back, so the student is unsaved again; show the parent errors with theirs.
      @student.errors.add(:base, "Parent or guardian: #{e.record.errors.full_messages.to_sentence.downcase}") unless e.record == @student
      render :new, status: :unprocessable_entity
    end

    def show
      @student = students.find(params[:id])
      @stage = @student.current_stage
      @stages = Stage.ordered.includes(:milestones)
      @checks = @student.skill_checks.index_by(&:milestone_id)
      @projects = @student.projects.includes(:reviews).order(updated_at: :desc)
      @interactions = @student.ai_interactions.recent.includes(:project).limit(30)
      @consent = @student.parent_consent
      @guardians = @student.guardianships.order(:created_at)
    end

    # Change one student's tier. Blank means "the default for their grade".
    def update
      student = students.find(params[:id])
      student.update!(ui_tier: tier_param)
      redirect_back_or_to teach_students_path, notice: "#{student.name} now sees #{student.tier_name}."
    end

    def bulk_tier
      ids = Array(params[:student_ids]).map(&:to_i)
      chosen = students.where(id: ids)
      return redirect_to(teach_students_path, alert: "Pick at least one student.") if chosen.none?
      chosen.find_each { |s| s.update!(ui_tier: tier_param) }
      label = tier_param ? User::TIERS.dig(tier_param, :name) : "their grade's tier"
      redirect_to teach_students_path(request.query_parameters.slice("classroom_id", "tier")), notice: "#{chosen.size} #{'student'.pluralize(chosen.size)} moved to #{label}."
    end

    def erase
      student = students.find(params[:id])
      name = student.name
      DataDeletion.erase!(student, reason: "staff_request", requested_by: current_user)
      redirect_to teach_classrooms_path, notice: "Deleted #{name}'s account and all their data."
    end

    private
      def tier_param
        value = params[:tier].to_s
        User::TIERS.key?(value) ? value : nil
      end
  end
end
