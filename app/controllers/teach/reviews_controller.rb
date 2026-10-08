module Teach
  class ReviewsController < BaseController
    before_action :set_interaction, except: :index

    def index
      @queue = interactions.needs_review.includes(:student, :project).order(Arel.sql("flag_severity = 'urgent' DESC"), :created_at)
      @help_needed = HelpSession.where(classroom_id: classrooms.select(:id)).needs_teacher.includes(:student, :project, :steps).order(:updated_at)
      @recently_reviewed = interactions.where.not(reviewed_at: nil).includes(:student, :reviewed_by).order(reviewed_at: :desc).limit(10)
    end

    def approve
      return redirect_to(teach_reviews_path, alert: "Only held answers can be sent.") unless @interaction.held?
      @interaction.deliver!(by: current_user)
      redirect_to teach_reviews_path, notice: "Sent to #{@interaction.student.first_name}."
    end

    def deny
      return redirect_to(teach_reviews_path, alert: "Only held answers can be stopped.") unless @interaction.held?
      if @interaction.guided?
        # The teacher will help in person instead of sending this hint.
        @interaction.help_session.update!(status: "escalated")
        @interaction.deny!("Your teacher is going to help you with this one in person.", by: current_user)
      else
        @interaction.deny!("Your teacher didn't send this answer. Ask them about it, or try asking a different way.", by: current_user)
      end
      redirect_to teach_reviews_path, notice: "Not sent."
    end

    # Flagged items already showed the student a safe message; this marks them as handled.
    def dismiss
      @interaction.update!(reviewed_by: current_user, reviewed_at: Time.current)
      redirect_to teach_reviews_path, notice: "Marked as reviewed."
    end

    private
      def set_interaction
        @interaction = interactions.find(params[:id])
      end
  end
end
