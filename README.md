# David Spatholt — Personal Website

Personal site at **david.spatholt.com** — a hub for academic research, software projects, and random LLM-built HTML apps.

## Stack

| Layer | Tool |
|---|---|
| Static site | Hand-built HTML/CSS (in `docs/`) |
| Optional CMS | Ghost (runs locally, exports to `docs/`) |
| App gallery | Auto-indexed from `docs/apps/` |
| Hosting | GitHub Pages (serves `docs/`) |
| CI/CD | GitHub Actions (auto-deploys on push) |

## Quick Start — Direct HTML Editing

```bash
# 1. Edit any file in docs/
# 2. Preview locally:
npx serve docs -l 4000
# 3. Deploy:
git add docs/
git commit -m "content: describe change"
git push
```

## Pushing a New HTML App (the key workflow)

1. Create `docs/apps/your-app-name/index.html`
2. Include metadata in `<head>` (auto-indexed):
   ```html
   <meta name="app:name" content="My App">
   <meta name="app:description" content="What it does">
   <meta name="app:tags" content="gemini,tool,visualization">
   <meta name="app:date" content="2026-06-18">
   ```
3. Commit and push. GitHub Actions auto-generates the gallery page.

## Ghost CMS (optional)

```bash
npm install
npm run ghost:install    # one-time
npm run ghost:start      # http://localhost:2368/ghost
# Write content, then:
npm run export            # Ghost → docs/
git add docs/ && git commit -m "content: ..." && git push
```

## Repo Structure

```
dspacks.github.io/
├── .github/workflows/
│   └── deploy.yml              # GitHub Pages deploy
├── docs/
│   ├── .nojekyll               # Blocks Jekyll interference
│   ├── assets/
│   │   ├── style.css           # Design system
│   │   └── nav.js              # Navigation
│   ├── index.html              # Homepage
│   ├── about/index.html        # Bio, CV, interests
│   ├── projects/index.html     # Major projects
│   ├── blog/...                # Ghost-exported or hand-written
│   ├── apps/
│   │   ├── index.html          # Auto-generated gallery ← THE HUB
│   │   ├── manifest.json       # Machine-readable index
│   │   └── app-name/           # Individual apps
│   │       └── index.html
│   └── ...other pages
├── inputs/                     # Strategy docs (not deployed)
├── scripts/
│   ├── export.sh               # Ghost → docs/ via wget
│   └── index-apps.sh           # Scan apps/ → generate gallery + manifest
├── package.json
└── README.md
```

## Custom Domain

This repo is configured for `david.spatholt.com`. Make sure a CNAME record pointing to `dspacks.github.io` exists at your DNS provider.
