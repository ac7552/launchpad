# A parent accepts an invite: makes a parent login (or adds this child to the one they have).
class JoinsController < ApplicationController
  allow_unauthenticated_access
  skip_before_action :enforce_consent, :touch_activity
  before_action :resume_session
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to join_path(params[:token]), alert: "Too many tries. Wait a few minutes." }
  before_action :set_guardianship

  def show
    @existing = User.find_by(username: @guardianship.email)
  end

  def create
    if @guardianship.claimed?
      return redirect_to(new_session_path, notice: "You're all set. Sign in with your email.")
    end

    if current_user&.parent? && current_user.username == @guardianship.email
      @guardianship.claim!(current_user)
      return redirect_to(family_child_path(@guardianship.student), notice: "#{@guardianship.student.first_name} is added to your account.")
    end

    if User.exists?(username: @guardianship.email)
      session[:return_to_after_authenticating] = join_url(@guardianship.token)
      return redirect_to(new_session_path, notice: "You already have a Launchpad login. Sign in to add #{@guardianship.student.first_name}.")
    end

    parent = User.new(role: "parent", username: @guardianship.email, name: params[:name].to_s.strip.presence || @guardianship.name,
                      password: params[:password], password_confirmation: params[:password_confirmation])
    if params[:password].to_s.length < 10
      parent.errors.add(:password, "must be at least 10 characters")
    elsif parent.save
      @guardianship.claim!(parent)
      start_new_session_for parent
      return redirect_to(family_child_path(@guardianship.student), notice: "Welcome! Here's #{@guardianship.student.first_name}'s work.")
    end
    @existing = nil
    @errors = parent.errors.full_messages
    render :show, status: :unprocessable_entity
  end

  private
    def set_guardianship
      @guardianship = Guardianship.find_by(token: params[:token].to_s)
      render("parents/gone", status: :not_found) unless @guardianship
    end
end
