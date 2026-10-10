# Launchpad curriculum: coding and problem solving first. AI-literate by the end of 6th grade without
# any chatbot use; students only type to the AI once they're 13.
# Each stage has three focus areas (coding, AI, computer skills) plus milestones students
# must pass to move up. Safe to re-run.

CURRICULUM = [
  {
    key: "g4", name: "Scratch → Smalruby blocks", grades: "4", min_grade: 4, max_grade: 4,
    kid_name: "Snap Blocks", emoji: "🧩",
    kid_coding: "Make things move, repeat, and react.",
    kid_ai: "Teach a computer with pictures. See how AI learns.",
    kid_computer: "Type fast. Save and find your work.",
    kid_project: "A game you control with your hands.",
    tool: "Blocks (Scratch-style)", editor: "blocks", ai_modes: %w[hint explain],
    coding_focus: "Loops, conditions, and events; breaking a game into small steps.",
    ai_focus: "How AI learns from examples: train an image or sound model in Teachable Machine (on the device) and use it in a game. Get unstuck with the guided coach's question cards — no chatting.",
    computer_focus: "Touch typing, files and folders, saving and naming work, online safety.",
    project_summary: "A gesture-controlled game using a model the kid trained.",
    milestones: [
      [ "coding", "Builds a game with loops, conditions, and events", "I made a game with a loop and an if." ],
      [ "ai", "Trains a simple image or sound model and tests where it gets confused", "I taught a computer with pictures and found where it gets mixed up." ],
      [ "ai", "Explains how AI works in kid terms: it learns patterns from examples and can be wrong", "I can say how AI learns: from examples. It can be wrong." ],
      [ "computer", "Types comfortably and can save and find their own files", "I can type well and find my files." ]
    ]
  },
  {
    key: "g5", name: "Smalruby: blocks + Ruby side by side", grades: "5", min_grade: 5, max_grade: 5,
    kid_name: "Blocks + Ruby", emoji: "🔤",
    kid_coding: "Read Ruby. Guess what it will do.",
    kid_ai: "Write a clear plan. Find mistakes in AI code.",
    kid_computer: "Use shortcuts. Keep your projects neat.",
    kid_project: "Write a game plan. Watch AI build it. Fix 3 bugs.",
    tool: "Blocks with live Ruby view", editor: "split", ai_modes: %w[hint explain fix build],
    coding_focus: "Reading Ruby, predicting what code will do, changing values in the Ruby view.",
    ai_focus: "Writing a clear spec, then checking AI-written code in teacher-led demos. Using the guided coach's hint ladder instead of asking for answers.",
    computer_focus: "Keyboard shortcuts, organizing projects, basic troubleshooting.",
    project_summary: "A one-page game spec → the teacher has AI build it on the big screen → the class finds and fixes three problems in Ruby.",
    milestones: [
      [ "coding", "Points to the Ruby line that matches a given block", "I can find the Ruby line for a block." ],
      [ "coding", "Changes a value in Ruby and predicts what will happen", "I can change a number in Ruby and guess what happens." ],
      [ "ai", "Writes a spec clear enough for someone else (or AI, in a teacher demo) to build", "I wrote a plan someone else could build." ],
      [ "ai", "Finds one mistake in AI-generated code", "I found a mistake in AI code." ]
    ]
  },
  {
    key: "g6", name: "Smalruby: Ruby first", grades: "6", min_grade: 6, max_grade: 6,
    kid_name: "Ruby First", emoji: "💎",
    kid_coding: "Write Ruby on your own. Test it.",
    kid_ai: "Plan, build, test, fix. Use a model you trained.",
    kid_computer: "Learn how the internet works.",
    kid_project: "A game run by a model you trained.",
    tool: "Ruby editor with blocks for checking", editor: "ruby_first", ai_modes: %w[hint explain fix build],
    coding_focus: "Writing Ruby (times, if, each, variables), splitting problems into parts, testing.",
    ai_focus: "Planning a build (plan → build → test → fix) with teacher-led AI, and making a project that uses a model they trained.",
    computer_focus: "How the internet works, file types, spreadsheets.",
    project_summary: "A game controlled by a model they trained. ✅ AI-literate milestone.",
    milestones: [
      [ "coding", "Writes a short Ruby program without blocks", "I wrote a Ruby program with no blocks." ],
      [ "coding", "Explains times, if, each, and variables in their own words", "I can explain times, if, each, and variables." ],
      [ "ai", "Reads AI-generated Ruby and explains what it does", "I can read AI code and say what it does." ],
      [ "ai", "Plans a multi-step build: plan → build → test → fix", "I can plan a build: plan, build, test, fix." ],
      [ "ai", "Builds a project that uses a model they trained", "I made a project with a model I trained." ],
      [ "ai", "Knows the rules: what not to share, when AI is allowed, how to say they used it", "I know the AI rules: what not to share, and when to use it." ]
    ]
  },
  {
    key: "g7", name: "Plain Ruby + Ruby2D", grades: "7", min_grade: 7, max_grade: 7,
    kid_name: "Real Ruby", emoji: "🎮",
    kid_coding: "Write your own methods and lists.",
    kid_ai: "At 13, ask the AI coach your own questions.",
    kid_computer: "Try the terminal.",
    kid_project: "A bigger game in Ruby.",
    tool: "Ruby editor", editor: "ruby", ai_modes: %w[hint explain fix build chat],
    coding_focus: "Methods, arrays, projects with multiple files.",
    ai_focus: "Once 13: typing questions to the AI coach about their project, with supervision. First calls to an AI API from Ruby.",
    computer_focus: "Cloud vs. local files, intro to the terminal.",
    project_summary: "A Ruby2D game with AI-generated levels or dialogue.",
    milestones: [
      [ "coding", "Writes and uses their own methods", "I wrote my own methods." ],
      [ "ai", "Uses AI to understand an error message, then fixes the bug themselves", "I used AI to understand an error. Then I fixed it myself." ],
      [ "computer", "Navigates folders and runs a program from the terminal", "I can run a program from the terminal." ]
    ]
  },
  {
    key: "g8", name: "Ruby2D, PicoRuby, git", grades: "8", min_grade: 8, max_grade: 8,
    kid_name: "Build & Share", emoji: "🔧",
    kid_coding: "Plan big projects. Save them with git.",
    kid_ai: "Tell AI helpers what to build. Check their work.",
    kid_computer: "Use the terminal and GitHub.",
    kid_project: "A gadget or web tool you share.",
    tool: "Ruby editor + hardware", editor: "ruby", ai_modes: %w[hint explain fix build chat],
    coding_focus: "Project planning, hardware programming, version control.",
    ai_focus: "Directing AI agents on larger projects and reviewing their code like a teammate's.",
    computer_focus: "Terminal, git and GitHub basics.",
    project_summary: "A hardware project or small web tool, shipped.",
    milestones: [
      [ "coding", "Builds a multi-file Ruby project and saves it with git", "I saved a big project with git." ],
      [ "ai", "Writes a spec, has AI build part of it, and tests the result", "I wrote a plan, AI built part of it, and I tested it." ],
      [ "computer", "Uses the terminal for everyday tasks", "I use the terminal every day." ]
    ]
  },
  {
    key: "g9_10", name: "Ruby on Rails", grades: "9–10", min_grade: 9, max_grade: 10,
    kid_name: "Web Apps", emoji: "🌐",
    kid_coding: "Build web apps with Rails.",
    kid_ai: "Add AI to your app, with safety rules.",
    kid_computer: "Put your app online. Keep it safe.",
    kid_project: "A web app real people use.",
    tool: "Rails", editor: "ruby", ai_modes: %w[hint explain fix build chat],
    coding_focus: "Databases, web apps, the request/response cycle, security basics.",
    ai_focus: "Adding AI features to their own apps, with rules and guardrails.",
    computer_focus: "Git workflows, deployment, password managers and 2FA.",
    project_summary: "A Rails app with an AI feature that real users use.",
    milestones: [
      [ "coding", "Deploys a working web app that other people use", "I put a web app online that people use." ],
      [ "coding", "Writes tests and can explain any code AI wrote", "I write tests and can explain all AI code." ],
      [ "ai", "Adds an AI feature with its own rules and guardrails", "I added an AI feature with safety rules." ]
    ]
  },
  {
    key: "g11_12", name: "Rails + AI agents", grades: "11–12", min_grade: 11, max_grade: 12,
    kid_name: "Launch!", emoji: "🚀",
    kid_coding: "Design big systems that don't break.",
    kid_ai: "Build AI agents. Check if they're good enough.",
    kid_computer: "Run real apps. Work on a team.",
    kid_project: "Your big launch: a real product.",
    tool: "Rails + agents", editor: "ruby", ai_modes: %w[hint explain fix build chat],
    coding_focus: "System design, testing, reliability.",
    ai_focus: "Multi-step agents, automation, checking whether AI output is good enough, AI ethics.",
    computer_focus: "Production deployment, monitoring, working on a team codebase.",
    project_summary: "Capstone: a deployed product with real users, a GitHub portfolio, and a log of how AI was used.",
    milestones: [
      [ "coding", "Designs and ships a capstone with real users", "I launched a project with real users." ],
      [ "ai", "Builds a multi-step agent and measures whether its output is good enough", "I built an AI agent and checked its work." ],
      [ "ai", "Documents how AI was used and decides on its limits and ethics", "I wrote how I used AI and where it should stop." ]
    ]
  }
].freeze

CURRICULUM.each_with_index do |attrs, i|
  stage = Stage.find_or_initialize_by(key: attrs[:key])
  stage.update!(attrs.except(:milestones).merge(position: i + 1))
  attrs[:milestones].each_with_index do |(category, description, kid_description), j|
    stage.milestones.find_or_initialize_by(position: j + 1).update!(category:, description:, kid_description:)
  end
  stage.milestones.where("position > ?", attrs[:milestones].size).destroy_all
end

# Development accounts, also used for a public demo (LAUNCHPAD_DEMO=1). A demo takes its password from
# LAUNCHPAD_DEMO_PASSWORD so the one in this file never works on a public site.
if Rails.env.development? || ENV["LAUNCHPAD_DEMO"] == "1"
  dev_password = Rails.env.development? ? "launchpad-dev" : ENV.fetch("LAUNCHPAD_DEMO_PASSWORD")

  # Demo usernames. Older seeds used ms.rivera and jalen; those accounts are renamed in place, not duplicated.
  renamed = { "admin_launchpad" => "ms.rivera", "student_launchpad" => "jalen" }
  find_account = ->(username) { User.find_by(username:) || User.find_by(username: renamed[username]) || User.new }

  teacher = find_account.("admin_launchpad")
  teacher.update!(username: "admin_launchpad", name: "Ms. Rivera", role: "admin", password: dev_password)

  room = Classroom.find_or_create_by!(name: "Room 12 — Grades 4–9", teacher:)
  room.policy.update!(light: "green") # shows both the guided coach and typed questions (13+ only)

  # Covers each consent state: maya (verified, no AI coach), student_launchpad (verified with AI coach),
  # priya (parent signed, needs staff verification), theo (waiting for parent), nia (13+, no consent needed).
  [ [ "maya", "Maya Lopez", 4, 2017, :verified_no_ai ], [ "student_launchpad", "Jalen Brooks", 5, 2016, :verified_ai ],
    [ "priya", "Priya Shah", 6, 2015, :submitted ], [ "theo", "Theo Kim", 7, 2013, :requested ],
    [ "nia", "Nia Okafor", 9, 2011, nil ] ].each do |username, name, grade, birth_year, consent_state|
    student = find_account.(username)
    student.update!(username:, name:, role: "student", grade:, birth_year:, password: dev_password)
    room.enrollments.find_or_create_by!(student:)
    next unless consent_state

    consent = student.parent_consent || student.create_parent_consent!(parent_name: "Parent of #{name.split.first}", parent_email: "#{username}.parent@example.com")
    case consent_state
    when :requested then consent.update!(status: "requested")
    when :submitted then consent.submit!(signature_name: consent.parent_name, ai_consent: true, ip: "127.0.0.1") unless consent.submitted?
    when :verified_no_ai, :verified_ai
      consent.submit!(signature_name: consent.parent_name, ai_consent: consent_state == :verified_ai, ip: "127.0.0.1") unless consent.verified?
      consent.verify!(by: teacher, method: "signed_form_in_person") unless consent.verified?
    end
  end

  # Parents: a guardian record for each family; Maya's parent already has a login (username = their email).
  User.students.find_each do |kid|
    consent = kid.parent_consent
    kid.guardianships.find_or_create_by!(email: consent&.parent_email || "#{kid.username}.parent@example.com") do |g|
      g.name = consent&.parent_name || "Parent of #{kid.first_name}"
    end
  end
  maya = User.find_by!(username: "maya")
  maya_parent = User.find_or_initialize_by(username: "maya.parent@example.com")
  maya_parent.update!(name: "Rosa Lopez", role: "parent", password: dev_password)
  maya.guardianships.find_by!(email: "maya.parent@example.com").then { |g| g.claim!(maya_parent) unless g.claimed? }
  thread = MessageThread.for(maya)
  if thread.messages.none?
    thread.messages.create!(author: maya, body: "I made the cat go in a square!")
    thread.messages.create!(author: teacher, body: "Amazing, Maya! Next time, can you make it say something at each corner?")
    thread.messages.create!(author: maya_parent, body: "She showed me at home. Thank you!")
  end

  # A turned-in project waiting to be graded.
  jalen = User.find_by!(username: "student_launchpad")
  turned_in = jalen.projects.order(:created_at).first || jalen.projects.create!(title: "Rocket square")
  turned_in.turn_in!(note: "I made it go in a square") if turned_in.reviews.none?

  puts "Dev accounts: admin admin_launchpad, students maya (4), student_launchpad (5), nia (9, 13+); priya and theo await parent permission; parent maya.parent@example.com. Password: see db/seeds.rb"
end

puts "Seeded #{Stage.count} stages and #{Milestone.count} milestones."
