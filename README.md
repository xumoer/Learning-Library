# Learning Library

A collection of self-contained, work-through-it HTML guides — one folder per skill. Hosted on GitHub Pages so embedded videos and external resources load over HTTPS and just work.

## Structure

```
learning-library/
├── index.html                      ← the hub / landing page (the card grid)
├── README.md
├── .nojekyll                       ← tells GitHub Pages to serve files as-is
└── skills/
    └── blender-rigging/
        └── index.html              ← Rigging & Animation in Blender 5.1
```

Each skill lives in its own folder under `skills/` and is named `index.html`, so it gets a clean URL like `…/skills/blender-rigging/`.


## Add a new skill

1. Make a folder: `skills/your-skill-name/` and put your guide in it as `index.html`.
2. Open `index.html` (the hub) and **duplicate one of the `<article class="card …">` blocks**. Change the title, blurb, call number, tags, status, and the `href` so it points to `skills/your-skill-name/index.html`.
3. Status options are just CSS classes: `solid` (green), `learning` (amber), `planned` (gray). Update the progress bar width (`<i style="width:NN%">`) as you go.
4. Commit and push — it's live.

The three gray "Planned" cards in the hub are placeholders. Edit or delete them freely.


