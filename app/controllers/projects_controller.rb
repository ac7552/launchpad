class ProjectsController < ApplicationController
  before_action :require_student
  before_action :set_project, only: %i[show update destroy back_to_blocks]

  def index
    @projects = current_user.projects.order(updated_at: :desc)
  end

  def new
    @project = current_user.projects.new
  end

  def create
    @project = current_user.projects.new(params.require(:project).permit(:title, :spec))
    if @project.save
      redirect_to @project
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @policy = @project.classroom&.policy
    @modes = @policy ? @policy.modes_for(current_user) : []
    @interactions = @project.ai_interactions.where(help_session_id: nil)
    @session = @project.help_sessions.active.last
  end

  # Autosave from the editor (JSON). The kid is the author of anything typed or snapped here.
  def update
    attrs = params.require(:project).permit(:title, :spec, :ruby_source, :blocks_json, :editor_mode)
    @project.title = attrs[:title] if attrs[:title].present?
    @project.spec = attrs[:spec] if attrs.key?(:spec)
    @project.editor_mode = "ruby" if attrs[:editor_mode] == "ruby"
    @project.save! if @project.changed?
    @project.apply_source!(attrs[:ruby_source], author: "kid", blocks_json: attrs[:blocks_json]) if attrs.key?(:ruby_source)

    render json: { saved_at: @project.updated_at, kid_share: @project.kid_share, needs_hand_edit: @project.needs_hand_edit? }
  end

  def back_to_blocks
    @project.update!(editor_mode: @project.stage.editor)
    redirect_to @project, notice: "Back to blocks. Your Ruby was rebuilt from your blocks."
  end

  def destroy
    @project.destroy!
    redirect_to root_path, notice: "Project deleted."
  end

  private
    def set_project
      @project = current_user.projects.find(params[:id])
    end
end
