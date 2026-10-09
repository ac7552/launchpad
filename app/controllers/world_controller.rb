class WorldController < ApplicationController
  def show
    return redirect_to(family_path) if current_user.parent?
    @spots = current_user.student? ? student_spots : staff_spots
  end

  # A place in the world. x and y are positions in the 3600×1000 picture.
  Spot = Struct.new(:key, :name, :x, :y, :label, :lines, :action, :path, keyword_init: true)

  private
    def student_spots
      last = current_user.projects.order(updated_at: :desc).first
      stage = current_user.current_stage
      passed = current_user.skill_checks.where(milestone: stage.milestones).count
      [
        Spot.new(key: "workshop", name: "The Workshop", x: 250, y: 370, label: "Projects",
                 lines: [ "This is where you build.", "All your projects live here." ], action: "Open my projects", path: projects_path),
        Spot.new(key: "coach", name: "Coach Bot", x: 800, y: 300, label: "AI coach",
                 lines: [ "Coach Bot helps when you're stuck.", "It asks you questions first.", "It's a computer program, so it can be wrong. Test its hints!" ]),
        Spot.new(key: "path", name: "The Path", x: 1520, y: 330, label: "Level #{stage.position}",
                 lines: [ "You're on Level #{stage.position}: #{stage.kid_name}.", "#{passed} of #{stage.milestones.size} goals done." ], action: "See my path", path: path_path),
        Spot.new(key: "library", name: "The Library", x: 2200, y: 400, label: "Rules",
                 lines: [ "🧠 Try first. Then ask the coach.", "✋ Change at least one thing.", "🗣️ Know what each line does.", "🔒 No names or photos." ]),
        Spot.new(key: "vault", name: "The Vault", x: 2700, y: 330, label: "Privacy",
                 lines: [ "Your stuff is locked up safe.", "Only your teacher can see your work." ], action: "How we keep it safe", path: privacy_path),
        Spot.new(key: "launch", name: "Launch Pad", x: 3200, y: 220, label: last ? "Keep building" : "Start",
                 lines: last ? [ "Ready for launch?", "Keep building #{last.title}." ] : [ "Ready for launch?", "Make your first project!" ],
                 action: last ? "Keep building" : "New project", path: last ? project_path(last) : new_project_path)
      ]
    end

    def staff_spots
      rooms = current_user.admin? ? Classroom.all : current_user.taught_classrooms
      kids = Enrollment.where(classroom: rooms).select(:student_id)
      waiting = AiInteraction.where(classroom: rooms).needs_review.count + HelpSession.where(classroom: rooms).needs_teacher.count
      verify = ParentConsent.where(student_id: kids).awaiting_staff.count
      grade = ProjectReview.waiting.joins(:project).where(projects: { student_id: kids }).count
      [
        Spot.new(key: "workshop", name: "The Workshop", x: 250, y: 370, label: "Students",
                 lines: [ "Every student in one place.", "Set tiers, see levels and goals, invite parents." ], action: "Open students", path: teach_students_path),
        Spot.new(key: "coach", name: "Coach Bot", x: 800, y: 300, label: "Review · #{waiting}",
                 lines: [ "#{waiting} #{waiting == 1 ? 'thing needs' : 'things need'} you.", "Held hints, flags, and kids who asked for you." ], action: "Open review queue", path: teach_reviews_path),
        Spot.new(key: "path", name: "The Path", x: 1520, y: 330, label: "Curriculum",
                 lines: [ "Seven levels, grades 4–12.", "Coding first. AI with a teacher." ], action: "Open curriculum", path: curriculum_path),
        Spot.new(key: "library", name: "The Library", x: 2200, y: 400, label: "Grading · #{grade}",
                 lines: [ "#{grade} #{grade == 1 ? 'project' : 'projects'} turned in.", "Score three things, write a few kind words." ], action: "Open grading", path: teach_grading_index_path),
        Spot.new(key: "vault", name: "The Vault", x: 2700, y: 330, label: "Permission · #{verify}",
                 lines: [ "#{verify} parent #{verify == 1 ? 'signature' : 'signatures'} to check.", "Privacy notice and data rules live here too." ], action: "Open permission", path: teach_consents_path),
        Spot.new(key: "launch", name: "Launch Pad", x: 3200, y: 220, label: "Classes",
                 lines: [ "Your classes and their AI rules.", "Start a new class here." ], action: "Open classes", path: teach_classrooms_path)
      ]
    end
end
