module Teach
  class HelpSessionsController < BaseController
    def resolve
      session = HelpSession.where(classroom_id: classrooms.select(:id)).find(params[:id])
      session.update!(status: "resolved", resolved_by: current_user, resolved_at: Time.current)
      session.broadcast_update
      redirect_to teach_reviews_path, notice: "Marked as helped."
    end
  end
end
