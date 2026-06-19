# David Spatholt Personal Site — Strategy

## Purpose

Personal hub for David Spatholt: emergency medicine researcher, developer, builder of random things.

**Audience:** Research collaborators, hiring managers, fellow developers, OSU colleagues, future self.

## Site Info Architecture

```
dspacks.github.io (davidspatholt.com)
├── Home          — Hero, what I do, featured projects, app gallery callout
├── About         — Bio, education, research areas, tools & tech
├── Projects      — Full project list with descriptions and GitHub links
├── Apps          — Auto-indexed gallery of LLM-built HTML apps
└── Ghost blog    — (optional) CMS-managed posts/pages
```

## Content Workflows

### 1. Direct HTML editing (daily use)
Edit any file in `docs/`, commit, push. GitHub Actions deploys in ~20 seconds.

### 2. Ghost CMS (optional, for blog/pages)
```bash
npm run ghost:install    # one-time
npm run ghost:start      # admin at http://localhost:2368/ghost
npm run export           # Ghost → docs/ via wget
git add docs/ && git commit -m "content: ..." && git push
```

### 3. Pushing a mini app
```bash
# 1. Create folder + HTML:
mkdir -p docs/apps/my-tool
# 2. Create index.html with metadata <meta> tags
# 3. Commit and push:
git add docs/apps/
git commit -m "apps: add my-tool"
git push
# GitHub Actions runs index-apps.sh → gallery + manifest auto-updated
```

This is the key workflow — push any single-file HTML app from any LLM and it shows up on the site automatically with no manual gallery editing.

## App Metadata Convention

Each app in `docs/apps/<name>/index.html` can declare metadata in `<head>`:

| Tag | Purpose | Example |
|---|---|---|
| `app:name` | Display name | `Content Calendar` |
| `app:description` | Short blurb | `Weekly content planning grid` |
| `app:tags` | Comma-separated | `gemini,react,tool` |
| `app:date` | ISO date | `2026-06-18` |

These feed the auto-indexer. If omitted, the indexer falls back to directory name + first `<h1>`.

## Repo Structure

```
dspacks.github.io/
├── .github/workflows/deploy.yml  # Pages deploy + app index generation
├── docs/                         # Live site (served by GitHub Pages)
│   ├── .nojekyll                 # Blocks Jekyll
│   ├── assets/
│   │   ├── style.css
│   │   └── nav.js
│   ├── index.html
│   ├── about/index.html
│   ├── projects/index.html
│   ├── apps/
│   │   ├── index.html            # Auto-generated gallery
│   │   ├── manifest.json         # Auto-generated metadata index
│   │   └── <app>/index.html
│   └── ... (Ghost-exported pages)
├── inputs/
│   └── site-strategy.md
├── scripts/
│   ├── export.sh                 # Ghost → docs/
│   └── index-apps.sh             # Scan apps/ → gallery + manifest
├── package.json
└── README.md
```

## Custom Domain Setup

1. In `dspacks.github.io` repo → Settings → Pages → set `davidspatholt.com`
2. At DNS provider: add CNAME record `davidspatholt.com` → `dspacks.github.io`
3. Update `scripts/export.sh` SITE_URL to `https://davidspatholt.com`

## Old WordPress Migration

Strategy:
1. Export WordPress as XML
2. Convert posts/pages to Markdown or straight HTML
3. Place in `docs/blog/` or as standalone pages under `docs/`
4. Optionally import into Ghost via its XML import feature for ongoing CMS use
