import { Controller } from "@hotwired/stimulus"

// Abel-style full-screen menu: MENU opens it, CLOSE or Escape closes it.
export default class extends Controller {
  static targets = ["panel", "toggle"]

  open() {
    this.panelTarget.hidden = false
    document.body.classList.add("menu-open")
    this.toggleTarget.setAttribute("aria-expanded", "true")
    this.panelTarget.querySelector("a, button")?.focus()
  }

  close() {
    this.panelTarget.hidden = true
    document.body.classList.remove("menu-open")
    this.toggleTarget.setAttribute("aria-expanded", "false")
    this.toggleTarget.focus()
  }

  closeOnEscape(event) {
    if (event.key === "Escape" && !this.panelTarget.hidden) this.close()
  }

  disconnect() {
    document.body.classList.remove("menu-open")
  }
}
