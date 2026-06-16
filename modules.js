/*
 * Documents Library — module data.
 * Add a document by copying the TEMPLATE object below into the MODULES array.
 * Shelves (grouped by type), filter buttons, call numbers (e.g. "TUT · 01"),
 * and the header counts are all generated from this file — no other edits needed.
 *
 * TEMPLATE (copy this, fill it in, drop it in the array):
 * {
 *   title:    "Your Document Title",          // required, plain text
 *   blurb:    "One or two sentences.",         // required
 *   type:     "Tutorial",                      // required; Tutorial | Info | Rules | Plan | …
 *                                              //   drives the shelf, filter button, and call-no prefix
 *   category: "Dev",                           // optional; topic — shown as a tag chip
 *   code:     "TUT",                           // optional; call-no prefix. Default derived from type
 *   tags:     ["topic", "topic"],              // optional; extra chips shown on the card
 *   status:   "learning",                      // optional; one of: "solid" | "learning" | "planned"
 *   href:     "library/your-doc/index.html",   // optional. Omit for a not-yet-written doc (inactive card)
 *   steps:    10,                              // optional; tutorials only — shown as "10 steps"
 *   progress: 0                                // optional; tutorials only — 0–100, progress-bar fill %
 * }
 */
window.MODULES = [
  {
    title:    "Rigging & Animation in Blender 5.1",
    blurb:    "Zero to animating a monster: armatures, weight painting, FK/IK, Rigify, walk cycles, and creature-specific techniques — with every 5.1 change flagged.",
    type:     "Tutorial",
    category: "3D",
    tags:     ["rigging", "animation", "blender"],
    status:   "learning",
    href:     "library/blender-rigging/index.html",
    steps:    10,
    progress: 0
  },
  {
    title:    "Pelvic Floor Training — Postpartum Prolapse to Lifting",
    blurb:    "From symptom relief to confident lifting: a staged pelvic-floor program covering prolapse recovery and load progression.",
    type:     "Tutorial",
    category: "Health",
    tags:     ["pelvic floor", "postpartum", "prolapse"],
    status:   "solid",
    href:     "library/pelvic-floor-training/pelvic-floor-training-guide.html",
    steps:    8,
    progress: 0
  },
  {
    title:    "Unified Dice Game",
    blurb:    "A unique table top rule set",
    type:     "Rules",
    category: "Game Rules",
    code:     "RUL",
    tags:     ["Games", "Rules", "Dice"],
    status:   "solid",
    href:     "library/UDS-Rules/GAME_RULES_v5.html",
    steps:    25,
    progress: 0
  },
  {
    title:    "Valley Signal — Business Plan",
    blurb:    "A local business's Google listing is its real front door now — and out here, most of those doors are dusty. Valley Signal keeps them fresh: hours, photos, posts, reviews, and a simple website, all maintained for the owner so they never have to think about it.",
    type:     "Plan",
    category: "Business",
    code:     "PLN",
    tags:     ["business", "plan", "work"],
    status:   "planned",
    href:     "library/business-plan/business-plan.html",
    steps:    11,
    progress: 0
  },
  {
    title:    "Godot 4: Build Your First 2D Platformer",
    blurb:    "A beginner's path from installing Godot 4 to exporting a small, playable 2D platformer, built around current (4.6) best practices and verified video lessons.",
    type:     "Tutorial",
    category: "Gamedev",
    code:     "TUT",
    tags:     ["godot", "gamedev", "2d", "platformer", "gdscript", "beginner"],
    status:   "learning",
    href:     "library/Godot4-2d-platformer/index.html",
    steps:    8,
    progress: 0
  }
];
