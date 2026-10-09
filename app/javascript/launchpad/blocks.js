// Smalruby-style blocks that generate Launchpad Ruby. Blockly is served from public/vendor as a global.
const BLOCKLY_URL = "/vendor/blockly-13.3.0/blockly.min.js"

const SPRITE_OPTIONS = [["🐈 cat", "cat"], ["🐕 dog", "dog"], ["🚀 rocket", "rocket"], ["⭐ star", "star"]]
const BACKGROUND_OPTIONS = [["sky", "sky"], ["grass", "grass"], ["night", "night"], ["space", "space"], ["sand", "sand"], ["white", "white"]]
const ORDER_ATOMIC = 0
const ORDER_RELATIONAL = 7
const ORDER_NONE = 99

// The world's palette: teal, lavender, mustard, sage, coral.
const MOTION = "#4fa3a5", LOOKS = "#a17fcf", CONTROL = "#e0a33a", OPERATORS = "#6aa84f", OUTPUT = "#e8735a"

const spriteField = { type: "field_dropdown", name: "SPRITE", options: SPRITE_OPTIONS }

const BLOCKS = [
  { type: "lp_move", message0: "%1 move %2 steps", args0: [spriteField, { type: "input_value", name: "STEPS", check: "Number" }],
    inputsInline: true, previousStatement: null, nextStatement: null, colour: MOTION },
  { type: "lp_turn", message0: "%1 turn %2 degrees", args0: [spriteField, { type: "input_value", name: "DEGREES", check: "Number" }],
    inputsInline: true, previousStatement: null, nextStatement: null, colour: MOTION },
  { type: "lp_go_to", message0: "%1 go to x: %2 y: %3", args0: [spriteField, { type: "input_value", name: "X", check: "Number" }, { type: "input_value", name: "Y", check: "Number" }],
    inputsInline: true, previousStatement: null, nextStatement: null, colour: MOTION },
  { type: "lp_point", message0: "%1 point in direction %2", args0: [spriteField, { type: "input_value", name: "DIR", check: "Number" }],
    inputsInline: true, previousStatement: null, nextStatement: null, colour: MOTION },
  { type: "lp_bounce", message0: "%1 if on edge, bounce", args0: [spriteField],
    previousStatement: null, nextStatement: null, colour: MOTION },
  { type: "lp_say", message0: "%1 say %2", args0: [spriteField, { type: "input_value", name: "TEXT" }],
    inputsInline: true, previousStatement: null, nextStatement: null, colour: LOOKS },
  { type: "lp_background", message0: "set background to %1", args0: [{ type: "field_dropdown", name: "BG", options: BACKGROUND_OPTIONS }],
    previousStatement: null, nextStatement: null, colour: LOOKS },
  { type: "lp_wait", message0: "wait %1 seconds", args0: [{ type: "input_value", name: "SECONDS", check: "Number" }],
    inputsInline: true, previousStatement: null, nextStatement: null, colour: CONTROL },
  { type: "lp_repeat", message0: "repeat %1 times", args0: [{ type: "input_value", name: "TIMES", check: "Number" }],
    message1: "%1", args1: [{ type: "input_statement", name: "DO" }],
    inputsInline: true, previousStatement: null, nextStatement: null, colour: CONTROL },
  { type: "lp_if_position", message0: "if %1 %2 %3 %4", args0: [
      spriteField,
      { type: "field_dropdown", name: "AXIS", options: [["x", "x"], ["y", "y"], ["direction", "direction"]] },
      { type: "field_dropdown", name: "OP", options: [[">", ">"], ["<", "<"], ["=", "=="]] },
      { type: "input_value", name: "VALUE", check: "Number" }],
    message1: "%1", args1: [{ type: "input_statement", name: "DO" }],
    inputsInline: true, previousStatement: null, nextStatement: null, colour: CONTROL },
  { type: "lp_random", message0: "pick random %1 to %2", args0: [{ type: "input_value", name: "FROM", check: "Number" }, { type: "input_value", name: "TO", check: "Number" }],
    inputsInline: true, output: "Number", colour: OPERATORS },
  { type: "lp_puts", message0: "print %1", args0: [{ type: "input_value", name: "TEXT" }],
    inputsInline: true, previousStatement: null, nextStatement: null, colour: OUTPUT }
]

const num = (n) => ({ shadow: { type: "math_number", fields: { NUM: n } } })
const txt = (t) => ({ shadow: { type: "text", fields: { TEXT: t } } })

const TOOLBOX = {
  kind: "categoryToolbox",
  contents: [
    { kind: "category", name: "Motion", colour: MOTION, contents: [
      { kind: "block", type: "lp_move", inputs: { STEPS: num(10) } },
      { kind: "block", type: "lp_turn", inputs: { DEGREES: num(15) } },
      { kind: "block", type: "lp_go_to", inputs: { X: num(0), Y: num(0) } },
      { kind: "block", type: "lp_point", inputs: { DIR: num(90) } },
      { kind: "block", type: "lp_bounce" }
    ] },
    { kind: "category", name: "Looks", colour: LOOKS, contents: [
      { kind: "block", type: "lp_say", inputs: { TEXT: txt("Hello!") } },
      { kind: "block", type: "lp_background" }
    ] },
    { kind: "category", name: "Control", colour: CONTROL, contents: [
      { kind: "block", type: "lp_wait", inputs: { SECONDS: num(1) } },
      { kind: "block", type: "lp_repeat", inputs: { TIMES: num(4) } },
      { kind: "block", type: "lp_if_position", inputs: { VALUE: num(100) } }
    ] },
    { kind: "category", name: "Numbers & text", colour: OPERATORS, contents: [
      { kind: "block", type: "lp_random", inputs: { FROM: num(1), TO: num(10) } },
      { kind: "block", type: "math_number" },
      { kind: "block", type: "text" },
      { kind: "block", type: "lp_puts", inputs: { TEXT: txt("Hi from Ruby!") } }
    ] }
  ]
}

let ready = null

export function loadBlockly() {
  ready ??= new Promise((resolve, reject) => {
    if (window.Blockly) return resolve(window.Blockly)
    const script = document.createElement("script")
    script.src = BLOCKLY_URL
    script.onload = () => resolve(window.Blockly)
    script.onerror = () => reject(new Error("Couldn't load the block editor."))
    document.head.appendChild(script)
  }).then((Blockly) => {
    Blockly.common.defineBlocksWithJsonArray(BLOCKS)
    return Blockly
  })
  return ready
}

let theme = null

// Matches Launchpad's look: rounded Nunito type and a light gray block menu.
function launchpadTheme(Blockly) {
  theme ??= Blockly.Theme.defineTheme("launchpad", {
    base: Blockly.Themes.Classic,
    fontStyle: { family: "Nunito, system-ui, sans-serif", weight: "800", size: 13 },
    componentStyles: { workspaceBackgroundColour: "#fffdf8", toolboxBackgroundColour: "#f1eadf", toolboxForegroundColour: "#3a3a35", flyoutBackgroundColour: "#f8f3ee", flyoutOpacity: 1 }
  })
  return theme
}

export function createWorkspace(Blockly, host) {
  return Blockly.inject(host, {
    toolbox: TOOLBOX,
    theme: launchpadTheme(Blockly),
    trashcan: true,
    sounds: false,
    renderer: "zelos",
    zoom: { controls: true, wheel: false, startScale: 0.8 },
    move: { scrollbars: true, drag: true, wheel: true }
  })
}

export function createRubyGenerator(Blockly) {
  const ruby = new Blockly.CodeGenerator("Ruby")
  ruby.INDENT = "  "

  ruby.init = function () { this.isInitialized = true }
  ruby.finish = (code) => code
  ruby.scrubNakedValue = (line) => `${line}\n`
  ruby.scrub_ = function (block, code, thisOnly) {
    const next = block.nextConnection?.targetBlock()
    return code + (next && !thisOnly ? this.blockToCode(next) : "")
  }

  const value = (block, gen, name, fallback) => gen.valueToCode(block, name, ORDER_NONE) || fallback
  const sprite = (block) => block.getFieldValue("SPRITE")
  const body = (block, gen) => gen.statementToCode(block, "DO") || `${ruby.INDENT}# add blocks here\n`

  ruby.forBlock.math_number = (block) => {
    const n = Number(block.getFieldValue("NUM"))
    return [String(n), n < 0 ? ORDER_RELATIONAL : ORDER_ATOMIC]
  }
  ruby.forBlock.text = (block) => [JSON.stringify(block.getFieldValue("TEXT")).replace(/#/g, "\\#"), ORDER_ATOMIC]
  ruby.forBlock.lp_move = (b, g) => `${sprite(b)}.move(${value(b, g, "STEPS", "10")})\n`
  ruby.forBlock.lp_turn = (b, g) => `${sprite(b)}.turn(${value(b, g, "DEGREES", "15")})\n`
  ruby.forBlock.lp_go_to = (b, g) => `${sprite(b)}.go_to(${value(b, g, "X", "0")}, ${value(b, g, "Y", "0")})\n`
  ruby.forBlock.lp_point = (b, g) => `${sprite(b)}.point(${value(b, g, "DIR", "90")})\n`
  ruby.forBlock.lp_bounce = (b) => `${sprite(b)}.bounce\n`
  ruby.forBlock.lp_say = (b, g) => `${sprite(b)}.say(${value(b, g, "TEXT", '""')})\n`
  ruby.forBlock.lp_background = (b) => `background("${b.getFieldValue("BG")}")\n`
  ruby.forBlock.lp_wait = (b, g) => `wait(${value(b, g, "SECONDS", "1")})\n`
  ruby.forBlock.lp_repeat = (b, g) => `${value(b, g, "TIMES", "1")}.times do\n${body(b, g)}end\n`
  ruby.forBlock.lp_if_position = (b, g) =>
    `if ${sprite(b)}.${b.getFieldValue("AXIS")} ${b.getFieldValue("OP")} ${value(b, g, "VALUE", "0")}\n${body(b, g)}end\n`
  ruby.forBlock.lp_random = (b, g) => [`rand(${value(b, g, "FROM", "1")}..${value(b, g, "TO", "10")})`, ORDER_ATOMIC]
  ruby.forBlock.lp_puts = (b, g) => `puts ${value(b, g, "TEXT", '""')}\n`

  return ruby
}

// A friendly starting program for brand-new block projects.
export const STARTER_BLOCKS = {
  blocks: {
    languageVersion: 0,
    blocks: [{
      type: "lp_say", x: 30, y: 30, fields: { SPRITE: "cat" }, inputs: { TEXT: txt("Let's go!") },
      next: { block: { type: "lp_repeat", inputs: { TIMES: num(4), DO: { block: {
        type: "lp_move", fields: { SPRITE: "cat" }, inputs: { STEPS: num(80) },
        next: { block: { type: "lp_turn", fields: { SPRITE: "cat" }, inputs: { DEGREES: num(90) } } }
      } } } } }
    }]
  }
}
