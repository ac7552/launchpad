// Draws the stage and plays back the actions a Ruby run recorded.
const W = 480, H = 360
const SPRITES = {
  cat: { emoji: "🐈", style: "flip" },
  dog: { emoji: "🐕", style: "flip" },
  rocket: { emoji: "🚀", style: "rotate", offset: 45 },
  star: { emoji: "⭐", style: "rotate", offset: 0 }
}
const BACKGROUNDS = {
  white: "#fffdf8", sky: "#cfe4ea", grass: "#d6e6c8", night: "#2b2f45", space: "#1d1c24", sand: "#f3e2c0"
}
const MOVE_SPEED = 0.45   // pixels per ms
const TURN_SPEED = 0.9    // degrees per ms
const MAX_STEP_MS = 400

export class Stage {
  constructor(canvas) {
    this.canvas = canvas
    this.ctx = canvas.getContext("2d")
    this.reset()
    this.draw()
  }

  reset() {
    this.sprites = {}
    this.background = "white"
    this.playing = false
  }

  stop() {
    this.playing = false
  }

  async play(actions, { onDone } = {}) {
    this.reset()
    this.playing = true
    for (const [op, name, a, b, c] of actions) {
      if (!this.playing) break
      const sprite = name ? (this.sprites[name] ||= { x: 0, y: 0, dir: 90, visible: true, say: null }) : null
      switch (op) {
        case "show": sprite.visible = true; break
        case "hide": sprite.visible = false; break
        case "say": sprite.say = a || null; break
        case "bg": this.background = BACKGROUNDS[a] ? a : "white"; break
        case "wait": await this.pause(parseFloat(a) * 1000); continue
        case "pos": await this.tween(sprite, parseFloat(a), parseFloat(b), parseFloat(c)); continue
      }
      this.draw()
    }
    this.draw()
    this.playing = false
    onDone?.()
  }

  tween(sprite, x, y, dir) {
    const from = { x: sprite.x, y: sprite.y, dir: sprite.dir }
    const turn = ((dir - from.dir + 540) % 360) - 180
    const distance = Math.hypot(x - from.x, y - from.y)
    const duration = Math.min(MAX_STEP_MS, Math.max(distance / MOVE_SPEED, Math.abs(turn) / TURN_SPEED, 16))
    return new Promise((resolve) => {
      const start = performance.now()
      const frame = (now) => {
        const t = this.playing ? Math.min(1, (now - start) / duration) : 1
        sprite.x = from.x + (x - from.x) * t
        sprite.y = from.y + (y - from.y) * t
        sprite.dir = from.dir + turn * t
        this.draw()
        t < 1 ? requestAnimationFrame(frame) : (sprite.dir = dir, resolve())
      }
      requestAnimationFrame(frame)
    })
  }

  pause(ms) {
    return new Promise((resolve) => {
      const end = performance.now() + ms
      const tick = () => (!this.playing || performance.now() >= end ? resolve() : requestAnimationFrame(tick))
      tick()
    })
  }

  draw() {
    const { ctx } = this
    ctx.fillStyle = BACKGROUNDS[this.background]
    ctx.fillRect(0, 0, W, H)
    this.drawGrid()
    for (const [name, sprite] of Object.entries(this.sprites)) {
      if (!sprite.visible) continue
      const sx = W / 2 + sprite.x, sy = H / 2 - sprite.y
      this.drawSprite(name, sprite, sx, sy)
      if (sprite.say) this.drawBubble(sprite.say, sx, sy - 34)
    }
  }

  drawGrid() {
    const { ctx } = this
    const dark = ["night", "space"].includes(this.background)
    ctx.strokeStyle = dark ? "rgba(255,255,255,0.08)" : "rgba(0,0,0,0.06)"
    ctx.lineWidth = 1
    for (let x = 0; x <= W; x += 40) { ctx.beginPath(); ctx.moveTo(x + 0.5, 0); ctx.lineTo(x + 0.5, H); ctx.stroke() }
    for (let y = 0; y <= H; y += 40) { ctx.beginPath(); ctx.moveTo(0, y + 0.5); ctx.lineTo(W, y + 0.5); ctx.stroke() }
    if (this.background === "space") {
      ctx.fillStyle = "rgba(255,255,255,0.7)"
      for (let i = 0; i < 40; i++) ctx.fillRect((i * 97) % W, (i * 53) % H, 2, 2)
    }
  }

  drawSprite(name, sprite, sx, sy) {
    const { ctx } = this
    const look = SPRITES[name] || SPRITES.cat
    ctx.save()
    ctx.translate(sx, sy)
    if (look.style === "rotate") ctx.rotate(((sprite.dir - 90 + 90 - look.offset) * Math.PI) / 180)
    else if (sprite.dir > 0 && sprite.dir < 180) ctx.scale(-1, 1)
    ctx.font = "40px 'Apple Color Emoji','Segoe UI Emoji','Noto Color Emoji',sans-serif"
    ctx.textAlign = "center"
    ctx.textBaseline = "middle"
    ctx.fillText(look.emoji, 0, 0)
    ctx.restore()
  }

  drawBubble(text, x, y) {
    const { ctx } = this
    ctx.font = "600 14px Nunito, system-ui, sans-serif"
    const lines = wrap(ctx, String(text).slice(0, 120), 160)
    const width = Math.max(...lines.map((l) => ctx.measureText(l).width)) + 20
    const height = lines.length * 18 + 12
    const left = Math.min(Math.max(x - width / 2, 4), W - width - 4)
    const top = Math.max(y - height, 4)
    ctx.fillStyle = "#fff"
    ctx.strokeStyle = "#3b3f5c"
    ctx.lineWidth = 2
    ctx.beginPath()
    ctx.roundRect(left, top, width, height, 10)
    ctx.fill(); ctx.stroke()
    ctx.fillStyle = "#1c1f33"
    ctx.textAlign = "left"
    ctx.textBaseline = "top"
    lines.forEach((line, i) => ctx.fillText(line, left + 10, top + 7 + i * 18))
  }
}

function wrap(ctx, text, max) {
  const words = text.split(/\s+/)
  const lines = []
  let line = ""
  for (const word of words) {
    const test = line ? `${line} ${word}` : word
    if (ctx.measureText(test).width > max && line) { lines.push(line); line = word } else line = test
  }
  lines.push(line)
  return lines
}
