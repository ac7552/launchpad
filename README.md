# Launchpad

A Rails platform for teaching coding, computer skills, and AI to grades 4–12.
Path: Scratch-style blocks → Smalruby-style blocks + Ruby → plain Ruby → Rails. Coding and problem
solving stay the main focus. Kids learn how AI works, how to build with it, and how to question it —
with a real teacher, not a chatbot.

## How the AI coach works

- **Under 13: guided coach only.** Students pick a question card (e.g. "What does this line do?") and
  climb a hint ladder: the coach asks them a multiple-choice question → points to a line → shows a tiny
  example → calls the teacher. They must try each hint (20s) before asking for the next. Students never
  type to the AI, and the coach never writes their solution.
- **13+ (by birth year, not grade):** can also type questions about their project, in green classes only.
- **Traffic light per class (NJSBA-style):** red = written hint bank, no AI; yellow = guided AI coach;
  green = guided + typed questions for 13+. Teachers can hold every AI hint for review.
- The AI only sees the project: code (names scrubbed), the card, the clicked line, and button presses.
  Replies are forced into a JSON format and checked; anything that breaks the rules is replaced by the
  hint bank. Every step is logged for teachers.

## Run it

```bash
bin/setup            # installs gems, prepares the database, seeds the curriculum + dev accounts
bin/rails server -p 3100
```

Dev accounts and their password are in `db/seeds.rb` (teacher `ms.rivera`; students `maya` (4), `jalen` (5), `priya` (6), `theo` (7), `nia` (9, 13+)).

AI: set `ANTHROPIC_API_KEY` (or `anthropic.api_key` in credentials) to use Claude. Without a key the
coach runs in **demo mode** with canned replies, so every flow still works offline.

```bash
bin/rails test       # models, AI gate/tutor, teacher flows, access rules
```

## Children's privacy (COPPA)

- Students under 13 (by birth year) can't sign in until a parent consents online **and** staff verify it
  (signed form in person, a scanned signed form, or a video call with ID). Staff record how they verified.
- The AI coach is a **separate** consent, because it shares project data with a third party (Anthropic).
  Without it the child gets the written hint bank. Turning it on later needs staff verification again;
  turning it off is instant.
- Parents use the link in their email to review, download (JSON), or delete their child's data, or to
  turn the AI coach off. Declining or deleting erases the account immediately; a `DataDeletion` record
  keeps proof of the deletion with no personal information.
- Data minimization: students are stored as first name + last initial; no child email, photos, or voice.
- Retention (`Launchpad::Privacy`, enforced daily by `PurgeExpiredDataJob`): unanswered requests deleted
  after 14 days, inactive accounts after 365 days, AI coach logs after 365 days.
- Public privacy notice at `/privacy`; the parent notice uses the same text.

**Before real families use it:** set `LAUNCHPAD_OPERATOR_NAME`, `_ADDRESS`, `_EMAIL`, `_PHONE`,
`LAUNCHPAD_HOST`, `LAUNCHPAD_MAIL_FROM`, and SMTP settings; have a lawyer review the notice and consent flow;
write the information security program the COPPA rule requires; and confirm Anthropic's current terms
for products used by minors. In development, emails are written to `tmp/mails`.

## How it fits together

| Piece | Where |
|---|---|
| Curriculum (7 stages × coding / AI / computer skills, 26 milestones) | `db/seeds.rb`, `Stage`, `Milestone` |
| Stage progression (pass every milestone to move up) | `User#current_stage`, `SkillCheck` |
| Block editor → Ruby generator | `app/javascript/launchpad/blocks.js` (Blockly) |
| Sandboxed Ruby in the browser + sprite library | `public/ruby_worker.js` (ruby.wasm in a Web Worker, 5s timeout, 2,000-action cap) |
| ruby.wasm and Blockly, served by the app (no CDN, so school filters can't block them) | `public/vendor/` |
| Stage animation | `app/javascript/launchpad/stage.js` |
| Editor (autosave, run, coach form) | `app/javascript/controllers/editor_controller.js` |
| Who wrote each line (student vs. coach) | `Project#apply_source!` |
| Question cards and hint ladder | `Ai::Cards`, `Ai::Guide`, `Ai::GuidedStep`, `HelpSession` |
| Written hint bank (red classes, no API key, and fallback) | `Ai::HintBank` |
| Typed-question gate (13+, green, daily limit, PII scrubbing) | `Ai::Gate`, `Ai::Scrubber`, `AiPolicy` |
| Safety screen (keyword pass + small model) | `Ai::SafetyCheck` |
| Tutor prompts by grade and mode | `Ai::Prompts` |
| Tutor call, hold-for-review, delivery | `Ai::Tutor`, `AiTutorJob` |
| Teacher dashboard, AI rules, milestones, review queue | `app/controllers/teach/*` |

AI never talks to the browser directly: every request goes through Rails, is logged as an
`AiInteraction`, and can be held for teacher review. The coach can only *propose* code; the
student accepts it, and those lines are marked as AI-written until the student changes them.

## Not built yet

- Ruby → blocks (editing Ruby in the split view pauses the blocks instead of updating them)
- Keyboard/mouse events on the stage, sprite costumes, sounds
- Teachable Machine integration (grade 4; training must stay on the device), Ruby2D/PicoRuby/Rails projects (grades 7+)
- A printable consent form for in-person verification
- Admin tools (schools, bulk rostering)
