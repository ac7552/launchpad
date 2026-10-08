import { Controller } from "@hotwired/stimulus"
import { loadBlockly, createWorkspace, createRubyGenerator, STARTER_BLOCKS } from "launchpad/blocks"
import { RubyRuntime } from "launchpad/runtime"
import { Stage } from "launchpad/stage"

const SAVE_DELAY_MS = 1200

// The project editor: blocks and/or Ruby, the stage, autosave, and the coach form.
export default class extends Controller {
  static targets = [
    "blocks", "ruby", "gutter", "canvas", "console", "runButton", "stopButton", "saveState", "runtimeState",
    "aiForm", "aiPrompt", "aiSource", "aiBlocks", "handEditBanner", "lineLabel"
  ]
  static values = { mode: String, saveUrl: String, blocks: String, wasmUrl: String }

  connect() {
    // Never run (or save) from a Turbo preview snapshot: it holds stale code.
    this.inactive = document.documentElement.hasAttribute("data-turbo-preview")
    if (this.inactive) return
    this.stage = new Stage(this.canvasTarget)
    this.runtime = new RubyRuntime(this.wasmUrlValue, { onStatus: (s, msg) => this.runtimeStatus(s, msg) })
    this.dirty = false
    this.syncGutter()
    if (this.hasBlocksTarget && this.blocksDrive) this.setupBlocks()
  }

  disconnect() {
    if (this.inactive) return
    clearTimeout(this.saveTimer)
    if (this.dirty) this.save()
    this.inactive = true
    this.runtime?.terminate()
    this.stage?.stop()
    this.workspace?.dispose()
  }

  // Blocks are the source of truth in "blocks" and "split" mode until the kid edits Ruby directly.
  get blocksDrive() {
    return ["blocks", "split"].includes(this.modeValue)
  }

  async setupBlocks() {
    try {
      const Blockly = await loadBlockly()
      this.blocksTarget.innerHTML = ""
      this.workspace = createWorkspace(Blockly, this.blocksTarget)
      this.generator = createRubyGenerator(Blockly)
      const state = this.blocksValue ? JSON.parse(this.blocksValue) : (this.rubyTarget.value.trim() ? null : STARTER_BLOCKS)
      if (state) Blockly.serialization.workspaces.load(state, this.workspace)
      // Loading fires the same events as editing. Only treat it as an edit if the blocks actually changed.
      this.lastBlocksJson = this.blocksJson()
      this.workspace.addChangeListener((event) => {
        if (event.isUiEvent || !this.blocksDrive || this.inactive) return
        const json = this.blocksJson()
        if (json === this.lastBlocksJson) return
        this.lastBlocksJson = json
        this.regenerateRuby()
        this.scheduleSave()
      })
      if (!this.blocksValue) { this.regenerateRuby(); this.scheduleSave() }
    } catch (error) {
      this.blocksTarget.innerHTML = `<p class="loading">${error.message}</p>`
    }
  }

  regenerateRuby() {
    if (!this.workspace) return
    this.rubyTarget.value = this.generator.workspaceToCode(this.workspace)
    this.syncGutter()
  }

  blocksJson() {
    if (!this.workspace || !this.blocksDrive) return null
    return JSON.stringify(window.Blockly.serialization.workspaces.save(this.workspace))
  }

  // --- Ruby text editor -------------------------------------------------------------

  rubyEdited() {
    if (this.modeValue === "split") {
      this.modeValue = "ruby"
      this.switchedToRuby = true
      this.element.querySelector(".pane-blocks")?.classList.add("is-paused")
    }
    this.syncGutter()
    this.scheduleSave()
  }

  rubyKeydown(event) {
    if (event.key !== "Tab" || this.rubyTarget.readOnly) return
    event.preventDefault()
    const el = this.rubyTarget
    const { selectionStart: start, selectionEnd: end } = el
    el.setRangeText("  ", start, end, "end")
    this.rubyEdited()
  }

  syncGutter() {
    const lines = this.rubyTarget.value.split("\n").length
    this.gutterTarget.textContent = Array.from({ length: lines }, (_, i) => i + 1).join("\n")
    this.gutterTarget.scrollTop = this.rubyTarget.scrollTop
  }

  // --- Saving -------------------------------------------------------------------------

  scheduleSave() {
    if (this.inactive) return
    this.dirty = true
    this.saveStateTarget.textContent = "Saving…"
    clearTimeout(this.saveTimer)
    this.saveTimer = setTimeout(() => this.save(), SAVE_DELAY_MS)
  }

  async save() {
    clearTimeout(this.saveTimer)
    if (!this.dirty) return
    this.dirty = false
    const project = { ruby_source: this.rubyTarget.value }
    const blocks = this.blocksJson()
    if (blocks) project.blocks_json = blocks
    if (this.switchedToRuby) project.editor_mode = "ruby"
    try {
      const response = await fetch(this.saveUrlValue, {
        method: "PATCH",
        headers: { "Content-Type": "application/json", "Accept": "application/json", "X-CSRF-Token": csrfToken() },
        body: JSON.stringify({ project })
      })
      if (!response.ok) throw new Error(response.statusText)
      const data = await response.json()
      this.saveStateTarget.textContent = "Saved ✓"
      if (this.hasHandEditBannerTarget && !data.needs_hand_edit) this.handEditBannerTarget.remove()
    } catch {
      this.dirty = true
      this.saveStateTarget.textContent = "Saving again…"
      this.saveTimer = setTimeout(() => this.save(), SAVE_DELAY_MS * 3)
    }
  }

  // Used by forms (like accepting the coach's code) that must not race unsaved edits.
  async saveBeforeSubmit(event) {
    const form = event.target
    if (form.dataset.saved === "true") return
    event.preventDefault()
    event.stopImmediatePropagation()
    await this.save()
    form.dataset.saved = "true"
    form.requestSubmit()
  }

  // --- Running ------------------------------------------------------------------------

  async run() {
    if (this.runtime.failed) return this.runtime.boot()
    this.runButtonTarget.disabled = true
    this.stopButtonTarget.disabled = false
    this.consoleTarget.textContent = ""
    this.consoleTarget.classList.remove("has-error")
    this.stage.stop()
    const result = await this.runtime.run(this.rubyTarget.value)
    this.consoleTarget.textContent = result.output || ""
    if (result.error) {
      this.consoleTarget.textContent += (result.output ? "\n" : "") + result.error
      this.consoleTarget.classList.add("has-error")
    }
    await this.stage.play(result.actions)
    this.runButtonTarget.disabled = false
    this.stopButtonTarget.disabled = true
  }

  stop() {
    this.stage.stop()
    this.stopButtonTarget.disabled = true
    this.runButtonTarget.disabled = false
  }

  runtimeStatus(status) {
    if (!this.hasRuntimeStateTarget) return
    const labels = { loading: "Getting ready…", ready: "Ready!", failed: "Couldn't load. Trying again…" }
    this.runtimeStateTarget.textContent = labels[status]
    this.runButtonTarget.disabled = status === "loading"
    this.runButtonTarget.textContent = status === "failed" ? "↻ Try again" : "▶ Run"
  }

  // --- Coach --------------------------------------------------------------------------

  prepareAiForm() {
    this.aiSourceTarget.value = this.rubyTarget.value
    this.aiBlocksTarget.value = this.blocksJson() || ""
  }

  aiSubmitted(event) {
    if (event.detail.success) this.aiPromptTarget.value = ""
  }

  aiModeChanged(event) {
    this.aiPromptTarget.placeholder = event.target.dataset.placeholder
  }

  // --- Guided coach -------------------------------------------------------------------

  // Remembers which line the student clicked, for the "What does this line do?" card.
  trackLine() {
    const before = this.rubyTarget.value.slice(0, this.rubyTarget.selectionStart)
    this.selectedLine = before.split("\n").length
    this.lineLabelTargets.forEach((el) => this.lineLabelTargetConnected(el))
  }

  lineLabelTargetConnected(el) {
    const text = this.selectedLine && this.rubyTarget.value.split("\n")[this.selectedLine - 1]?.trim()
    el.textContent = text ? `Line ${this.selectedLine}: ${text.slice(0, 40)}` : "Tap a line in your code first"
    el.classList.toggle("is-set", Boolean(text))
  }

  prepareCoachForm(event) {
    const form = event.target
    const field = (name) => form.querySelector(`[data-coach-field='${name}']`)
    field("line").value = this.selectedLine || ""
    field("error").value = this.consoleTarget.classList.contains("has-error") ? this.consoleTarget.textContent.slice(-300) : ""
    field("source").value = this.rubyTarget.value
    field("blocks").value = this.blocksJson() || ""
  }

  // "Look at line N" chips in the coach jump to and select that line.
  highlightLine(event) {
    const line = Number(event.currentTarget.dataset.line)
    const lines = this.rubyTarget.value.split("\n")
    if (!line || line > lines.length) return
    const start = lines.slice(0, line - 1).reduce((sum, l) => sum + l.length + 1, 0)
    this.rubyTarget.focus()
    this.rubyTarget.setSelectionRange(start, start + lines[line - 1].length)
    const lineHeight = parseFloat(getComputedStyle(this.rubyTarget).lineHeight) || 22
    this.rubyTarget.scrollTop = Math.max(0, (line - 3) * lineHeight)
    this.rubyTarget.closest(".pane").scrollIntoView({ behavior: "smooth", block: "nearest" })
    this.selectedLine = line
  }
}

function csrfToken() {
  return document.querySelector("meta[name='csrf-token']")?.content
}
