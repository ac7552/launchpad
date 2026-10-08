class PrivacyController < ApplicationController
  allow_unauthenticated_access
  skip_before_action :enforce_consent, :touch_activity
  # Public page, but still show the nav when someone is signed in.
  before_action :resume_session

  def show
  end
end
