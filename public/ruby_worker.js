// Runs student Ruby in a sandboxed Web Worker using ruby.wasm. Each run gets a fresh VM,
// so nothing leaks between runs. The page terminates this worker if a run takes too long.
// Served from Launchpad itself (public/vendor) so school web filters and CDN outages can't block it.
importScripts("/vendor/ruby-wasm-2.10.1/browser.umd.js")

const { DefaultRubyVM } = self["ruby-wasm-wasi"]
const SEP_FIELD = "\u001f", SEP_ACTION = "\u001e", SEP_PART = "\u001d"

// The Launchpad sprite library. Ruby computes where sprites end up; the page animates the
// recorded actions afterwards, so loops and conditions work without async code.
const PRELUDE = String.raw`
module Launchpad
  LIMIT = 2000
  HALF_W = 240.0
  HALF_H = 180.0
  STRIP = "\u001d\u001e\u001f"
  class TooManySteps < StandardError; end

  @actions = []
  @output = +""
  @sprites = {}

  class << self
    attr_reader :actions, :output

    def record(*fields)
      raise TooManySteps, "Your program did more than #{LIMIT} sprite actions. Is there a loop that never stops?" if @actions.size >= LIMIT
      @actions << fields.map { |f| f.to_s.delete(STRIP) }
    end

    def write(text)
      @output << text.to_s.delete(STRIP)
      raise TooManySteps, "Your program printed too much. Is there a loop that never stops?" if @output.size > 20_000
    end

    def sprite(name) = (@sprites[name] ||= Sprite.new(name))

    def run(code)
      error = ""
      begin
        TOPLEVEL_BINDING.eval(code, "project.rb", 1)
      rescue TooManySteps => e
        error = e.message
      rescue ScriptError, StandardError, SystemStackError => e
        error = friendly(e)
      end
      [@actions.map { |a| a.join("\u001f") }.join("\u001e"), @output, error].join("\u001d")
    end

    def friendly(e)
      line = (e.backtrace || []).map { |l| l[/\Aproject\.rb:(\d+)/, 1] }.compact.first
      line ||= e.message[/project\.rb:(\d+)/, 1]
      message = e.message.gsub(/project\.rb:\d+:\s*/, "").lines.first.to_s.strip
      hint =
        case e
        when NoMethodError then "Check the spelling of the method, and that you're calling it on the right thing."
        when NameError then "Ruby doesn't know this name. Check the spelling, or make sure you set the variable first."
        when SyntaxError then "Ruby couldn't read this. Look for a missing \"end\", quote, or parenthesis."
        when ZeroDivisionError then "You can't divide by zero."
        when ArgumentError then "A method got the wrong number or kind of values."
        when SystemStackError then "A method keeps calling itself forever."
        end
      ["Error#{" on line #{line}" if line}: #{message}", hint].compact.join("\n")
    end
  end

  class Sprite
    attr_reader :name, :x, :y, :direction

    def initialize(name)
      @name = name
      @x = 0.0
      @y = 0.0
      @direction = 90.0
      Launchpad.record("show", name)
    end

    def move(steps = 10)
      radians = (90 - @direction) * Math::PI / 180
      @x = (@x + steps.to_f * Math.cos(radians)).clamp(-HALF_W, HALF_W)
      @y = (@y + steps.to_f * Math.sin(radians)).clamp(-HALF_H, HALF_H)
      place
    end

    def turn(degrees = 15)
      @direction = normalize(@direction + degrees.to_f)
      place
    end

    def point(degrees = 90)
      @direction = normalize(degrees.to_f)
      place
    end

    def go_to(x, y)
      @x = x.to_f.clamp(-HALF_W, HALF_W)
      @y = y.to_f.clamp(-HALF_H, HALF_H)
      place
    end

    def bounce
      @direction = normalize(-@direction) if @x.abs >= HALF_W - 0.5
      @direction = normalize(180 - @direction) if @y.abs >= HALF_H - 0.5
      place
    end

    def say(text = "")
      Launchpad.record("say", @name, text)
      self
    end

    def hide = (Launchpad.record("hide", @name); self)
    def show = (Launchpad.record("show", @name); self)
    def to_s = @name
    def inspect = "#<sprite #{@name} x=#{@x.round} y=#{@y.round} direction=#{@direction.round}>"

    private

    def place
      Launchpad.record("pos", @name, @x.round(2), @y.round(2), @direction.round(2))
      self
    end

    def normalize(d)
      d = d % 360
      d > 180 ? d - 360 : d
    end
  end
end

def cat = Launchpad.sprite("cat")
def dog = Launchpad.sprite("dog")
def rocket = Launchpad.sprite("rocket")
def star = Launchpad.sprite("star")
def wait(seconds = 1) = Launchpad.record("wait", "", seconds.to_f.clamp(0, 10))
def sleep(seconds = 1) = wait(seconds)
def background(name = "white") = Launchpad.record("bg", "", name)

def puts(*args)
  args = [""] if args.empty?
  args.flatten.each { |a| s = a.to_s; Launchpad.write(s.end_with?("\n") ? s : "#{s}\n") }
  nil
end

def print(*args)
  args.each { |a| Launchpad.write(a.to_s) }
  nil
end

def p(*args)
  args.each { |a| Launchpad.write("#{a.inspect}\n") }
  args.size <= 1 ? args.first : args
end
`

let modulePromise = null

// Streams when the server sends the right type; otherwise falls back to a plain download.
async function compile(url) {
  const response = await fetch(url)
  if (!response.ok) throw new Error(`download failed (${response.status})`)
  if (response.headers.get("content-type")?.includes("application/wasm")) return WebAssembly.compileStreaming(response)
  return WebAssembly.compile(await response.arrayBuffer())
}

function rubyString(code) {
  // A JSON string is a valid Ruby double-quoted string once interpolation is escaped.
  return JSON.stringify(code).replace(/#/g, "\\#")
}

self.onmessage = async (event) => {
  const { type } = event.data
  if (type === "init") {
    modulePromise ??= compile(event.data.wasmUrl)
    try {
      await modulePromise
      self.postMessage({ type: "ready" })
    } catch (error) {
      modulePromise = null
      self.postMessage({ type: "fatal", message: error.message })
    }
    return
  }

  if (type === "run") {
    try {
      const module = await modulePromise
      const { vm } = await DefaultRubyVM(module, { consolePrint: false })
      vm.eval(PRELUDE)
      const raw = vm.eval(`Launchpad.run(${rubyString(event.data.code)})`).toString()
      const [actionText, output, error] = raw.split(SEP_PART)
      const actions = actionText ? actionText.split(SEP_ACTION).map((a) => a.split(SEP_FIELD)) : []
      self.postMessage({ type: "result", id: event.data.id, actions, output, error })
    } catch (error) {
      self.postMessage({ type: "result", id: event.data.id, actions: [], output: "", error: `Launchpad error: ${error.message}` })
    }
  }
}
