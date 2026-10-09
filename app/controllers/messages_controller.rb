# One shared conversation per student. Everyone in it (the student, their parents, their
# teachers) sees every message, so no adult ever messages a child privately.
class MessagesController < ApplicationController
  rate_limit to: 20, within: 1.minute, only: :create, with: -> { redirect_back_or_to messages_path, alert: "Slow down a little!" }
  before_action :set_thread, only: %i[show create]

  def index
    if current_user.student?
      redirect_to message_thread_path(current_user)
    elsif current_user.parent?
      kids = current_user.children.to_a
      return redirect_to(message_thread_path(kids.first)) if kids.one?
      @threads = kids.map { |kid| MessageThread.for(kid) }
    else
      ids = User.students.joins(:enrollments).where(enrollments: { classroom_id: staff_classrooms.select(:id) }).select(:id)
      @threads = MessageThread.where(student_id: ids).where.not(last_message_at: nil).includes(:student).order(last_message_at: :desc)
      @urgent_ids = Message.where(message_thread: @threads, urgent: true).distinct.pluck(:message_thread_id)
    end
  end

  def show
    @messages = @thread.messages.includes(:author)
    @thread.mark_read!(current_user)
  end

  def create
    message = @thread.messages.new(author: current_user, body: params[:body].to_s.strip.truncate(1000, omission: ""))
    if message.save
      @thread.mark_read!(current_user)
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace("composer", partial: "messages/composer", locals: { thread: @thread }) }
        format.html { redirect_to message_thread_path(@thread.student) }
      end
    else
      redirect_to message_thread_path(@thread.student), alert: "Type a message first."
    end
  end

  private
    def set_thread
      student = User.students.find(params[:student_id])
      @thread = MessageThread.for(student)
      raise ActiveRecord::RecordNotFound unless @thread.participant?(current_user)
    end

    def staff_classrooms = current_user.admin? ? Classroom.all : current_user.taught_classrooms
end
