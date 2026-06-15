# Learning Library

A personal collection of self-contained, work-through-it HTML guides — one folder per skill. Hosted on GitHub Pages so embedded videos and external resources load over HTTPS and just work (no local server, no Node).

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

## Publish on GitHub Pages (one time, ~3 minutes)

1. Create a new repository on GitHub, e.g. `learning-library` (public).
2. Put these files in it and push:
   ```bash
   cd learning-library
   git init
   git add .
   git commit -m "Initial learning library"
   git branch -M main
   git remote add origin https://github.com/YOUR-USERNAME/learning-library.git
   git push -u origin main
   ```
3. On GitHub: **Settings → Pages**. Under *Build and deployment*, set **Source = Deploy from a branch**, **Branch = main**, **folder = / (root)**. Save.
4. Wait ~1 minute. Your library is live at:
   ```
   https://YOUR-USERNAME.github.io/learning-library/
   ```
   The Blender tutorial is at `…/learning-library/skills/blender-rigging/`.
5. Edit the repo link at the bottom of `index.html` to point at your repo.

## Add a new skill

1. Make a folder: `skills/your-skill-name/` and put your guide in it as `index.html`.
2. Open `index.html` (the hub) and **duplicate one of the `<article class="card …">` blocks**. Change the title, blurb, call number, tags, status, and the `href` so it points to `skills/your-skill-name/index.html`.
3. Status options are just CSS classes: `solid` (green), `learning` (amber), `planned` (gray). Update the progress bar width (`<i style="width:NN%">`) as you go.
4. Commit and push — it's live.

The three gray "Planned" cards in the hub are placeholders. Edit or delete them freely.

## Preview locally before pushing (optional)

From inside the `learning-library` folder:

```bash
python -m http.server 8000
```

Then open `http://localhost:8000/`. Serving over `http://` (instead of double-clicking the file, which opens it as `file://`) is what makes the embedded YouTube videos play locally. GitHub Pages does the same thing over `https://` once it's published.

## Why the videos broke as a plain file

A file opened directly from disk runs as `file://`, which has no real origin or referrer. Browsers and YouTube's embed checks treat that as untrusted, so some embeds refuse to load. Any real web origin — `http://localhost` for testing, or `https://…github.io` in production — solves it. No backend is involved; the embeds are just iframes.
