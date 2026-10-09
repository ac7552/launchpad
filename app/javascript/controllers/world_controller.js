import { Controller } from "@hotwired/stimulus"

const WORLD_WIDTH = 3600

// The world: drag (or scroll, or use arrow keys) to look around; tap a glowing spot to read its story.
export default class extends Controller {
  static targets = ["viewport", "hint", "panel", "panelBody", "story", "progress", "place"]

  connect() {
    this.scrolled()
  }

  // Mouse drag pans the picture. Touch uses the browser's own swipe scrolling.
  grab(event) {
    if (event.pointerType !== "mouse" || event.button !== 0) return
    const vp = this.viewportTarget
    const startX = event.clientX
    const startLeft = vp.scrollLeft
    this.dragged = false
    vp.classList.add("is-grabbing")
    const move = (e) => {
      const dx = e.clientX - startX
      if (Math.abs(dx) > 4) this.dragged = true
      vp.scrollLeft = startLeft - dx
    }
    const up = () => {
      vp.classList.remove("is-grabbing")
      window.removeEventListener("pointermove", move)
      window.removeEventListener("pointerup", up)
    }
    window.addEventListener("pointermove", move)
    window.addEventListener("pointerup", up)
  }

  // A normal mouse wheel moves sideways through the world.
  wheel(event) {
    if (Math.abs(event.deltaY) <= Math.abs(event.deltaX)) return
    event.preventDefault()
    this.viewportTarget.scrollLeft += event.deltaY
  }

  scrolled() {
    const vp = this.viewportTarget
    const max = vp.scrollWidth - vp.clientWidth
    const ratio = max > 0 ? vp.scrollLeft / max : 0
    this.progressTarget.style.width = `${Math.round(ratio * 100)}%`
    if (vp.scrollLeft > 40) this.hintTarget.classList.add("is-gone")

    // Light up the place in the middle of the screen, so kids always know where they are.
    const middle = ((vp.scrollLeft + vp.clientWidth / 2) / vp.scrollWidth) * WORLD_WIDTH
    let nearest = null
    for (const place of this.placeTargets) {
      const distance = Math.abs(Number(place.dataset.worldXParam) - middle)
      if (!nearest || distance < nearest.distance) nearest = { place, distance }
    }
    // At either end, the first or last place can't reach the middle, so pick it outright.
    if (vp.scrollLeft <= 2) nearest = { place: this.placeTargets[0] }
    if (max > 0 && vp.scrollLeft >= max - 2) nearest = { place: this.placeTargets.at(-1) }
    this.placeTargets.forEach((p) => p.classList.toggle("is-here", p === nearest?.place))
  }

  prev() { this.scrollBy(-0.6) }
  next() { this.scrollBy(0.6) }

  scrollBy(screens) {
    const vp = this.viewportTarget
    vp.scrollBy({ left: vp.clientWidth * screens, behavior: this.motion })
  }

  // Jump to a place from the strip at the bottom, then open its story.
  jump(event) {
    const vp = this.viewportTarget
    const x = (event.params.x / WORLD_WIDTH) * vp.scrollWidth
    vp.scrollTo({ left: x - vp.clientWidth / 2, behavior: this.motion })
    this.show(event.params.spot)
  }

  open(event) {
    if (this.dragged) { this.dragged = false; return }
    this.show(event.params.spot)
  }

  show(key) {
    const story = this.storyTargets.find((t) => t.dataset.spot === key)
    if (!story) return
    this.panelBodyTarget.replaceChildren(story.content.cloneNode(true))
    this.panelTarget.hidden = false
    this.element.querySelectorAll(".spot").forEach((s) => s.classList.toggle("is-open", s.matches(`.spot-${key}`)))
    // Open on the other side from the place, so the panel never covers what it's about.
    const spot = this.element.querySelector(`.spot-${key}`)
    const target = (Number(spot.style.left.replace("%", "")) / 100) * this.viewportTarget.scrollWidth
    const onRight = target - this.viewportTarget.scrollLeft > this.viewportTarget.clientWidth / 2
    this.panelTarget.classList.toggle("is-left", onRight)
    this.panelTarget.querySelector(".btn, .panel-close")?.focus({ preventScroll: true })
  }

  close() {
    this.panelTarget.hidden = true
    this.element.querySelectorAll(".spot.is-open").forEach((s) => s.classList.remove("is-open"))
    this.viewportTarget.focus({ preventScroll: true })
  }

  key(event) {
    if (event.key === "Escape" && !this.panelTarget.hidden) return this.close()
    if (event.target.closest("input, textarea, select")) return
    if (event.key === "ArrowRight") { event.preventDefault(); this.scrollBy(0.3) }
    if (event.key === "ArrowLeft") { event.preventDefault(); this.scrollBy(-0.3) }
  }

  get motion() {
    return window.matchMedia("(prefers-reduced-motion: reduce)").matches ? "auto" : "smooth"
  }
}
