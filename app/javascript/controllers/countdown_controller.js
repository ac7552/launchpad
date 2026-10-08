import { Controller } from "@hotwired/stimulus"

// Keeps "still stuck" disabled until the student has had time to try the hint.
export default class extends Controller {
  static targets = ["button", "label"]
  static values = { seconds: Number }

  connect() {
    this.remaining = this.secondsValue
    if (this.remaining > 0) this.timer = setInterval(() => this.tick(), 1000)
  }

  disconnect() {
    clearInterval(this.timer)
  }

  tick() {
    this.remaining -= 1
    if (this.remaining > 0) {
      this.labelTarget.textContent = `Try it first · ${this.remaining}`
      return
    }
    clearInterval(this.timer)
    this.labelTarget.textContent = ""
    this.buttonTargets.forEach((b) => (b.disabled = false))
  }
}
