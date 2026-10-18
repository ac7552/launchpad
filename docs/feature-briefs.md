# Launchpad — Feature Briefs

Short specs for five planned features, in recommended build order. Decisions reached in planning are
noted inline. Nothing here is built yet.

**Build order:** Live classroom view → Analytics → Offline/export → Browser terminal → Ruby → blocks.

---

## 1. Live classroom view

**What:** A real-time teacher dashboard showing every enrolled student's current state during class —
their stage/milestone, who's stuck, who's idle, and who has an open help request.

**Why:** Teachers can already grade and set AI rules, but have no at-a-glance "pulse" of the room while
students work. This is the highest daily-value, lowest-risk feature.

**Approach:**
- Build on existing models: `Classroom`, `Enrollment`, `User#current_stage`, `SkillCheck`, `HelpSession`.
- Push updates with Turbo Streams / ActionCable (no polling).
- Define "stuck" explicitly, e.g. an open `HelpSession` past the hint ladder, or idle past N minutes.
- Add a `Teach::` controller + view; reuse the teacher auth already in `app/controllers/teach/*`.

**Effort:** Medium. Mostly real-time wiring + a status query; no new data model.

---

## 2. Analytics

**What:** Aggregate dashboards on how students move through the curriculum and where they get stuck —
milestone pass/fail rates, hint-ladder escalations, teacher-call frequency, grading trends.

**Why:** The data already exists and is unused for insight. Lets teachers/curriculum tune the hardest
spots. Shares queries with the Live view.

**Approach:**
- Source from existing logs: `AiInteraction`, `HelpSession`, `SkillCheck`, `ProjectReview`.
- **Privacy rule (hard):** aggregate / cohort-level only — never per-child surveillance — to stay
  consistent with the COPPA and data-minimization posture.
- Charts in a `Teach::Analytics` view.

**Effort:** Low–Medium. Aggregation + charting over data that's already captured.

---

## 3. Offline / export

**What:** Let a student export their sprite project to take home — ideally a **runnable** standalone
HTML that bundles their code + ruby.wasm so it runs in any browser offline.

**Why:** Privacy-aligned (data goes to the kid's own device) and motivating (show family what they made).

**Approach:**
- Reuse `public/ruby_worker.js` + the vendored ruby.wasm/Blockly in `public/vendor/`.
- Decision pending: **runnable standalone HTML** (preferred, more fun) vs. a flat archive of code + assets.
- **Distinct from** the existing parent *data* export (`StudentExport`), which is a COPPA data-access
  feature, not a project share.

**Effort:** Medium. Packaging + a self-contained HTML template.

---

## 4. Browser terminal (advanced students, Docker-backed)

**What:** A real containerized shell in the browser for advanced students — reaches the top of the
ladder (plain Ruby → Rails projects) that ruby.wasm can't run.

**Why:** ruby.wasm can't run Rails or a real filesystem/gems. This unlocks the "Rails projects,
grades 7+" item from the README's "Not built yet."

**Decisions reached:**
- **Scope:** max **two containers at a time** (small demo/classroom), so capacity is a non-issue.
- **Host:** runs on the **existing droplet** (shared with Curb) — not a separate exec host.
- **Gating:** 13+ / green classes / Launch Crew only, teacher-enabled per student, each session logged
  like `AiInteraction`.

**Approach:**
- **2-slot session pool:** request → claim a free slot → spin an ephemeral container → stream PTY to
  **xterm.js** over a websocket (ActionCable). Idle timeout + hard wall-clock cap → teardown frees the
  slot. Both busy → "terminals in use, try shortly" (no queue).
- **Exec broker (important):** do **not** mount `/var/run/docker.sock` into the web container. A small
  local broker service exposes only "start a hardened container in a free slot" / "tear it down" — it
  never accepts arbitrary commands. Keeps host-root off the web app.
- **Container hardening (all of these):** `--network none` (or tight allowlist), memory/CPU/PID limits,
  ulimits, `--cap-drop ALL`, `--security-opt no-new-privileges`, read-only rootfs + writable tmpfs,
  non-root user, wall-clock kill. Install **gVisor (`runsc`)** on the droplet if possible — biggest
  isolation win on a shared box.
- Student files mount as a dedicated volume — never touching Curb data or the student SQLite volume.

**Open decision:** container image = **plain Ruby + IRB** (light) vs. **full Rails + gem set** (heavier,
unlocks Rails projects).

**Effort:** High, and the riskiest. Blocked on the image decision above; mostly code + hardening, no new
infra beyond installing a runtime.

---

## 5. Ruby → blocks round-trip

**What:** Make the block editor two-way — edit Ruby and have the Blockly blocks update, instead of the
current behavior of pausing the blocks when Ruby is edited.

**Why:** Completes the core learning ladder (blocks ⇄ Ruby ⇄ Rails). Listed in "Not built yet."

**Approach:**
- Today `app/javascript/launchpad/blocks.js` generates Ruby one-way (blocks → Ruby).
- Reverse direction needs: parse Ruby → AST → map onto Blockly blocks, **and** a defined fallback for
  code that has no block equivalent (advanced students will write plenty).
- Current "pause the blocks on Ruby edit" is a reasonable interim stance.

**Effort:** High — research-grade. Sequenced **last** deliberately.

---

_Last updated: 2026-10-18._
