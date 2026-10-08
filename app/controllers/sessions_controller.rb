class SessionsController < ApplicationController
  allow_unauthenticated_access only: %i[ new create ]
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to new_session_url, alert: "Too many tries. Wait a few minutes." }

  def new
  end

  def create
    user = User.authenticate_by(params.permit(:username, :password))
    if user && !user.can_sign_in?
      redirect_to new_session_path, alert: "Your account is waiting for a parent's permission. Ask your teacher."
    elsif user
      start_new_session_for user
      redirect_to after_authentication_url
    else
      redirect_to new_session_path, alert: "That username or password didn't work."
    end
  end

  def destroy
    terminate_session
    reset_session # don't carry a return-to URL over to the next person on a shared Chromebook
    redirect_to new_session_path
  end
end
