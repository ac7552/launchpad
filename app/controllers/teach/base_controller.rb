module Teach
  class BaseController < ApplicationController
    before_action :require_staff

    private
      def classrooms
        current_user.admin? ? Classroom.all : current_user.taught_classrooms
      end

      def students
        User.students.joins(:enrollments).where(enrollments: { classroom_id: classrooms.select(:id) }).distinct
      end

      def interactions
        AiInteraction.where(classroom_id: classrooms.select(:id))
      end
  end
end
