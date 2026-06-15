/*
 * Learning Library — module data.
 * Add a new guide by copying the TEMPLATE object below into the MODULES array.
 * Cards, filter buttons, call numbers (e.g. "3D · 01"), and the header counts
 * are all generated from this file — no other edits needed.
 *
 * TEMPLATE (copy this, fill it in, drop it in the array):
 * {
 *   title:    "Your Module Title",        // required, plain text
 *   blurb:    "One or two sentences.",     // required
 *   category: "Dev",                       // required; makes a filter button + call-no prefix
 *   code:     "DEV",                        // optional; call-no prefix. Default = category, first 3 chars, uppercased
 *   tags:     ["Dev", "topic", "topic"],  // optional; chips shown on the card
 *   status:   "learning",                  // required; one of: "solid" | "learning" | "planned"
 *   href:     "skills/your-skill/index.html", // optional. Omit (or use status:"planned") for a placeholder card
 *   steps:    10,                           // optional; shown in the footer, e.g. "10 steps"
 *   progress: 0                             // optional; 0–100; progress-bar fill %
 * }
 */
window.MODULES = [
  {
    title:    "Rigging & Animation in Blender 5.1",
    blurb:    "Zero to animating a monster: armatures, weight painting, FK/IK, Rigify, walk cycles, and creature-specific techniques — with every 5.1 change flagged.",
    category: "3D",
    code:     "3D",
    tags:     ["3D", "rigging", "animation", "blender"],
    status:   "learning",
    href:     "skills/blender-rigging/index.html",
    steps:    10,
    progress: 8
  },
  {
    title:    "Pelvic Floor Training — Postpartum Prolapse to Lifting",
    blurb:    "From symptom relief to confident lifting: a staged pelvic-floor program covering prolapse recovery and load progression.",
    category: "Health",
    code:     "HLT",
    tags:     ["Health", "pelvic floor", "postpartum", "prolapse"],
    status:   "solid",
    href:     "skills/pelvic-floor-training/pelvic-floor-training-guide.html",
    steps:    8,
    progress: 100
  }
];
