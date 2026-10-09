import { Controller } from "@hotwired/stimulus"

// Marks your own messages and keeps the newest one in view, including ones that arrive live.
export default class extends Controller {
  static values = { me: Number }

  connect() {
    this.mark()
    this.observer = new MutationObserver(() => this.mark())
    this.observer.observe(this.element, { childList: true })
  }

  disconnect() {
    this.observer?.disconnect()
  }

  mark() {
    this.element.querySelectorAll(".msg").forEach((m) => m.classList.toggle("mine", Number(m.dataset.author) === this.meValue))
    this.element.lastElementChild?.scrollIntoView({ block: "end" })
  }
}
