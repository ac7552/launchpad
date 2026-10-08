class AiInteractionsController < ApplicationController
  before_action :require_student
  rate_limit to: 8, within: 1.minute, only: :create, with: -> { head :too_many_requests }

  def create
    @project = current_user.projects.find(params[:project_id])
    # Save the kid's latest code first so the coach sees exactly what they see.
    if params[:ruby_source]
      @project.apply_source!(params[:ruby_source], author: "kid", blocks_json: params[:blocks_json].presence)
    end
    @interaction = Ai::Gate.call(student: current_user, project: @project, mode: params[:mode], prompt: params[:prompt])

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to @project }
    end
  end

  def accept
    interaction = find_open_proposal
    project = interaction.project
    project.apply_source!(interaction.proposed_code, author: "ai")
    project.update!(editor_mode: "ruby") if project.editor_mode.in?(%w[blocks split])
    interaction.update!(proposal_state: "accepted")
    redirect_to project, notice: "The coach's code is in your Ruby view. Read it, run it, and make at least one change yourself."
  end

  def reject
    interaction = find_open_proposal
    interaction.update!(proposal_state: "rejected")
    redirect_to interaction.project, notice: "Proposal skipped."
  end

  private
    def find_open_proposal
      interaction = current_user.ai_interactions.find(params[:id])
      raise ActiveRecord::RecordNotFound unless interaction.open_proposal?
      interaction
    end
end
