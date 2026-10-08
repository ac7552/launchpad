module Teach
  class AiPoliciesController < BaseController
    def update
      classroom = classrooms.find(params[:classroom_id])
      attrs = params.require(:ai_policy).permit(:light, :review_required, :daily_limit, allowed_modes: [])
      attrs[:allowed_modes] ||= []
      if classroom.policy.update(attrs)
        redirect_to teach_classroom_path(classroom), notice: "AI rules updated."
      else
        redirect_to teach_classroom_path(classroom), alert: classroom.policy.errors.full_messages.to_sentence
      end
    end
  end
end
