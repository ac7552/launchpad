# The guided coach. Students never type here: they pick a question card, answer the coach's
# multiple-choice questions, and report "it worked" or "still stuck" after trying each hint.
module Ai
  class Guide
    class Refused < StandardError; end

    MAX_ERROR_TEXT = 300

    # Starts a session from a question card. Raises Refused with a kid-friendly message.
    def self.start(student:, project:, card:, line_number: nil, error_text: nil)
      classroom = project.classroom || student.primary_classroom
      policy = classroom && AiPolicy.find_by(classroom_id: classroom.id)
      raise Refused, "The coach isn't set up for your class yet. Ask your teacher." unless policy
      raise Refused, "Pick one of the question cards." unless card.in?(Ai::Cards.keys)
      raise Refused, "That's all your help for today. You've got this!" if student.ai_requests_today >= policy.daily_limit

      line_number = line_number.presence&.to_i
      line_text = line_number&.positive? ? project.ruby_source.lines[line_number - 1]&.chomp : nil
      if Ai::Cards.fetch(card)[:needs_line] && line_text.to_s.strip.empty?
        raise Refused, "Tap a line in your code first. Then pick this card."
      end

      names = [ student.name ] + (classroom.students.pluck(:name) + [ classroom.teacher.name ])
      session = nil
      HelpSession.transaction do
        project.help_sessions.active.where(status: "open").update_all(status: "abandoned")
        session = HelpSession.create!(
          student:, project:, classroom:, card:, source: policy.hint_source_for(student),
          line_number: (line_number if line_text), line_text: line_text && Ai::Scrubber.call(line_text, names:).text,
          error_text: Ai::Scrubber.call(error_text.to_s.truncate(MAX_ERROR_TEXT, omission: ""), names:).text.presence
        )
      end
      add_step!(session, 1)
      session
    end

    # Records the student's button press and moves the session along.
    def self.respond(session:, choice:)
      step = session.current_step
      raise Refused, "This help session is finished. Pick a new card to start again." unless session.open? && step&.delivered?

      if choice == HelpSession::WORKED
        step.update!(kid_choice: choice)
        session.update!(status: "solved")
      elsif step.level == 1 && Array(step.choices).include?(choice)
        # Answering the coach's question is the thinking we want; no waiting needed.
        step.update!(kid_choice: choice)
        add_step!(session, 2)
      elsif choice == HelpSession::STUCK && step.level > 1
        wait = session.seconds_until_next_hint
        raise Refused, "Try the hint first! Next hint in #{wait} seconds." if wait.positive?
        step.update!(kid_choice: choice)
        add_step!(session, step.level + 1)
      else
        raise Refused, "Pick one of the buttons."
      end
      session.broadcast_update
      session
    end

    def self.add_step!(session, level)
      session.update!(level:)
      step = session.steps.create!(
        student: session.student, project: session.project, classroom: session.classroom,
        mode: "guided", level:, step_kind: HelpSession::STEP_KINDS.fetch(level),
        prompt: session.description, code_snapshot: session.project.ruby_source, status: "pending"
      )
      if level == HelpSession::TEACHER_LEVEL
        step.update!(status: "delivered", delivered_at: Time.current, model: "launchpad",
                     response_text: "I asked your teacher to come help. While you wait, read your code out loud, one #{session.project.editor_mode.in?(%w[blocks split]) ? 'block' : 'line'} at a time.")
        session.update!(status: "escalated")
      elsif session.source == "bank"
        Ai::GuidedStep.call(step) # Pre-written hints are instant; no AI involved.
      else
        GuidedStepJob.set(wait: 0.5.seconds).perform_later(step)
      end
      step
    end
  end
end
