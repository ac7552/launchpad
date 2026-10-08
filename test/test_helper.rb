ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

# The curriculum is reference data every test needs; seed it once, outside test transactions.
Rails.application.load_seed if Stage.none?

module ActiveSupport
  class TestCase
    parallelize(workers: 1)

    def create_teacher(username = "teacher")
      User.create!(name: "Ms. Test", username:, role: "teacher", password: "secret-pass")
    end

    # Under-13 students get a verified parent consent (with the AI coach allowed) unless told otherwise.
    def create_student(username = "kid", grade: 5, classroom: nil, age: grade + 5, consent: :verified_ai)
      student = User.create!(name: "Sam Rivera", username:, role: "student", grade:, birth_year: Date.current.year - age - 1,
                             password: "secret-pass")
      classroom&.enrollments&.create!(student:)
      give_consent(student, consent) if student.consent_required? && consent
      student
    end

    def give_consent(student, state)
      consent = student.create_parent_consent!(parent_name: "Pat Rivera", parent_email: "pat@example.com")
      return consent if state == :requested
      consent.submit!(signature_name: "Pat Rivera", ai_consent: state == :verified_ai, ip: "127.0.0.1")
      consent.verify!(by: User.find_by(role: "teacher") || create_teacher("verifier"), method: "signed_form_in_person") unless state == :submitted
      consent
    end

    def create_classroom(teacher = create_teacher, light: "yellow")
      Classroom.create!(name: "Room 1", teacher:).tap { |c| c.policy.update!(light:) }
    end

    # Stands in for the Anthropic client so AI paths can be tested without network calls.
    class FakeClaude
      Response = Struct.new(:content, :stop_reason, :model, :usage)
      Block = Struct.new(:type, :text)
      Usage = Struct.new(:input_tokens, :output_tokens)
      attr_reader :requests

      def initialize(*replies) = (@replies = replies; @requests = [])
      def beta = self
      def messages = self

      def create(**params)
        @requests << params
        Response.new([ Block.new(:text, @replies.shift.to_json) ], :end_turn, "claude-opus-5-5", Usage.new(100, 20))
      end
    end

    # Pretends an API key is configured and routes calls to a FakeClaude.
    def with_fake_claude(*replies)
      fake = FakeClaude.new(*replies)
      originals = { client: Ai.method(:client), live?: Ai.method(:live?) }
      Ai.define_singleton_method(:client) { fake }
      Ai.define_singleton_method(:live?) { true }
      yield fake
    ensure
      originals&.each { |name, method| Ai.define_singleton_method(name, method) }
    end
  end
end
