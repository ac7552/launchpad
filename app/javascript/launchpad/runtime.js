// Talks to the Ruby worker. Keeps one worker warm; replaces it if a run hangs.
const RUN_TIMEOUT_MS = 5000
const RETRY_DELAYS_MS = [2000, 5000, 15000]

export class RubyRuntime {
  constructor(wasmUrl, { onStatus } = {}) {
    this.wasmUrl = wasmUrl
    const report = onStatus || (() => {})
    this.onStatus = (status) => { this.status = status; report(status) }
    this.nextId = 1
    this.failures = 0
    this.boot()
  }

  boot() {
    clearTimeout(this.retryTimer)
    this.worker?.terminate()
    this.worker = new Worker("/ruby_worker.js")
    this.ready = new Promise((resolve, reject) => {
      const listener = ({ data }) => {
        if (data.type === "ready") { this.worker.removeEventListener("message", listener); resolve() }
        if (data.type === "fatal") { this.worker.removeEventListener("message", listener); reject(new Error(data.message)) }
      }
      this.worker.addEventListener("message", listener)
    })
    this.onStatus("loading")
    this.ready.then(
      () => { this.failures = 0; this.onStatus("ready") },
      () => {
        // A flaky connection shouldn't strand a kid: retry a few times, then let Run try again.
        const delay = RETRY_DELAYS_MS[this.failures++]
        this.onStatus("failed")
        if (delay) this.retryTimer = setTimeout(() => this.boot(), delay)
      }
    )
    this.worker.postMessage({ type: "init", wasmUrl: this.wasmUrl })
  }

  async run(code) {
    await this.ready
    const id = this.nextId++
    return new Promise((resolve) => {
      const timer = setTimeout(() => {
        this.worker.removeEventListener("message", listener)
        this.boot()
        resolve({ actions: [], output: "", error: "Your program ran for more than 5 seconds, so Launchpad stopped it. Is there a loop that never ends?" })
      }, RUN_TIMEOUT_MS)
      const listener = ({ data }) => {
        if (data.type !== "result" || data.id !== id) return
        clearTimeout(timer)
        this.worker.removeEventListener("message", listener)
        resolve(data)
      }
      this.worker.addEventListener("message", listener)
      this.worker.postMessage({ type: "run", id, code })
    })
  }

  get failed() {
    return this.status === "failed"
  }

  terminate() {
    clearTimeout(this.retryTimer)
    this.worker?.terminate()
  }
}
