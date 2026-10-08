class HelpSessionsController < ApplicationController
  before_action :require_student
  rate_limit to: 20, within: 1.minute, only: %i[create respond], with: -> { head :too_many_requests }

  def create
    @project = current_user.projects.find(params[:project_id])
    @project.apply_source!(params[:ruby_source], author: "kid", blocks_json: params[:blocks_json].presence) if params[:ruby_source]
    @session = Ai::Guide.start(student: current_user, project: @project, card: params[:card],
                               line_number: params[:line_number], error_text: params[:error_text])
    render_coach
  rescue Ai::Guide::Refused => e
    render_coach(notice: e.message)
  end

  def respond
    @session = current_user.help_sessions.find(params[:id])
    @project = @session.project
    Ai::Guide.respond(session: @session, choice: params[:choice].to_s)
    render_coach
  rescue Ai::Guide::Refused => e
    render_coach(notice: e.message)
  end

  def abandon
    @session = current_user.help_sessions.find(params[:id])
    @project = @session.project
    @session.update!(status: "abandoned") if @session.open?
    @session = nil
    render_coach
  end

  private
    def render_coach(notice: nil)
      @session&.reload
      render turbo_stream: turbo_stream.replace("coach_guided", partial: "help_sessions/coach",
             locals: { project: @project, session: @session, notice: })
    end
end
