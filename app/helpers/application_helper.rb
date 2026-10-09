module ApplicationHelper
  CATEGORY_LABELS = { "coding" => "Coding", "ai" => "AI", "computer" => "Computer skills" }.freeze

  # Renders coach text: paragraphs plus ```ruby fenced code, with everything escaped.
  def coach_text(text)
    parts = text.to_s.split(/```(?:ruby)?\s*\n?(.*?)```/m)
    safe_join(parts.each_with_index.map do |part, i|
      i.odd? ? tag.pre(tag.code(part.rstrip), class: "code") : simple_format(h(part.strip).gsub(/`([^`]+)`/, '<code>\1</code>').html_safe, {}, sanitize: false)
    end)
  end

  # True when a message thread this person can see has something new for them.
  def unread_messages?(user)
    threads =
      if user.student? then MessageThread.where(student_id: user.id)
      elsif user.parent? then MessageThread.where(student_id: user.children.select(:id))
      else
        rooms = user.admin? ? Classroom.all : user.taught_classrooms
        MessageThread.where(student_id: Enrollment.where(classroom: rooms).select(:student_id))
      end
    threads.where.not(last_message_at: nil).any? { |t| t.unread_for?(user) }
  end

  def stars(score) = safe_join(Array.new(4) { |i| tag.span(i < score.to_i ? "★" : "☆", class: (i < score.to_i ? "star on" : "star")) })

  # Launchpad's mark: the same green app icon as the browser tab.
  def brand_mark(size: 30)
    tag.img(src: "/icon.svg", alt: "", width: size, height: size, class: "brand-mark")
  end

  # A picture for a project card, from the sprites it uses.
  def project_emoji(project)
    code = project.ruby_source.to_s
    { "rocket" => "🚀", "dog" => "🐕", "star" => "⭐", "cat" => "🐈" }.find { |name, _| code.include?("#{name}.") }&.last ||
      (project.editor_mode.in?(%w[blocks split]) ? "🧩" : "💎")
  end

  def mode_label(mode) = Ai::MODE_LABELS.fetch(mode, mode.to_s.humanize)

  def category_label(category) = CATEGORY_LABELS.fetch(category, category.humanize)

  def status_badge(interaction)
    label = { "pending" => "Thinking…", "held" => "Waiting for teacher", "delivered" => "Answered",
              "denied" => "Not sent", "flagged" => "Flagged", "error" => "Error" }.fetch(interaction.status)
    tag.span(label, class: "badge badge-#{interaction.status}")
  end

  def editor_label(editor)
    { "blocks" => "Blocks", "split" => "Blocks + Ruby", "ruby_first" => "Ruby first", "ruby" => "Ruby" }.fetch(editor, editor)
  end
end
