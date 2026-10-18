# Launchpad Roadmap

The work ahead, in recommended build order. Each item links to a fuller brief in
[`docs/feature-briefs.md`](docs/feature-briefs.md). Nothing here is built yet.

| # | Feature | Value | Effort | Status |
|---|---------|-------|--------|--------|
| 1 | Live classroom view | High | Medium | Planned |
| 2 | Analytics | High | Low–Medium | Planned |
| 3 | Offline / export | Medium | Medium | Planned |
| 4 | Browser terminal (Docker-backed) | High | High | Planned |
| 5 | Ruby → blocks round-trip | High | High | Planned |

---

### 1. Live classroom view
Real-time teacher dashboard showing each student's stage/milestone, who's stuck, who's idle, and open
help requests. Builds on `Classroom`, `Enrollment`, `User#current_stage`, `SkillCheck`, `HelpSession`
with Turbo Streams / ActionCable. Highest daily value, lowest risk — do this first.

### 2. Analytics
Aggregate dashboards on curriculum progress and sticking points (milestone pass/fail, hint-ladder
escalations, teacher calls, grading trends), sourced from existing `AiInteraction`, `HelpSession`,
`SkillCheck`, `ProjectReview` logs. **Aggregate/cohort-level only — never per-child** — to keep the
COPPA and data-minimization posture. Shares queries with the Live view.

### 3. Offline / export
Let a student export their sprite project to take home, ideally a runnable standalone HTML bundling
their code + ruby.wasm (reusing `public/ruby_worker.js` and vendored assets). Distinct from the parent
data export (`StudentExport`). _Open decision: runnable HTML vs. flat archive._

### 4. Browser terminal (advanced students, Docker-backed)
A real containerized shell in the browser for advanced students, reaching the Rails rung ruby.wasm
can't run.
- **Scope:** max two containers at a time.
- **Host:** runs on the existing droplet.
- **Gating:** 13+ / green classes / Launch Crew, teacher-enabled, each session logged like `AiInteraction`.
- **Design:** 2-slot session pool → ephemeral container → PTY streamed to xterm.js over ActionCable;
  idle/wall-clock timeout tears down and frees the slot. A small **exec broker** starts/stops hardened
  containers so the web app never holds the Docker socket. Hardening: `--network none`, memory/CPU/PID
  limits, `--cap-drop ALL`, `--security-opt no-new-privileges`, read-only rootfs + tmpfs, non-root user,
  and gVisor (`runsc`) if available. Student files mount as a dedicated volume.
- _Open decision: image = plain Ruby + IRB vs. full Rails + gem set._

### 5. Ruby → blocks round-trip
Make the block editor two-way: parse edited Ruby back into Blockly blocks instead of pausing them, with
a defined fallback for code that has no block equivalent. Completes the blocks ⇄ Ruby ⇄ Rails ladder.
Research-grade; sequenced last.
