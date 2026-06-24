#!/usr/bin/env bash
# index-apps.sh — Scan docs/apps/ for HTML apps and regenerate:
#   1. docs/apps/manifest.json  (machine-readable index)
#   2. docs/apps/index.html     (human-readable gallery page)
#
# Each app subdirectory under docs/apps/ should contain index.html.
# Metadata is read from <meta> tags in the HTML <head>:
#
#   <meta name="app:name"        content="My App">
#   <meta name="app:description" content="What it does">
#   <meta name="app:tags"        content="gemini,react,tool">
#   <meta name="app:date"        content="2026-06-18">
#
# If name/description are missing, they're inferred from the filename and first <h1>.

APPS_DIR="docs/apps"
MANIFEST="$APPS_DIR/manifest.json"
GALLERY="$APPS_DIR/index.html"
GALLERY_TITLE="Mini Apps"

# Ensure apps dir exists
mkdir -p "$APPS_DIR"

apps=()
for app_dir in "$APPS_DIR"/*/; do
  [ -d "$app_dir" ] || continue
  app_name=$(basename "$app_dir")
  [ "$app_name" = "assets" ] && continue  # skip shared assets if any
  [ "$app_name" = "template" ] && continue # skip the starter template page

  html_file="${app_dir}index.html"
  [ -f "$html_file" ] || continue

  # Skip hidden drafts/templates/noindex pages
  if grep -qE '^[[:space:]]*<body[^>]*class="[^"]*(is-template|is-placeholder|is-draft)|^[[:space:]]*<body[^>]*data-(status|visibility)="(template|placeholder|draft)"|^[[:space:]]*<meta[^>]*name="robots"[^>]*content="noindex' "$html_file"; then
    continue
  fi

  # Extract metadata from <meta> tags
  meta_name=$(grep -oP '<meta\s+name="app:name"\s+content="([^"]*)"' "$html_file" | sed 's/.*content="\([^"]*\)".*/\1/')
  meta_desc=$(grep -oP '<meta\s+name="app:description"\s+content="([^"]*)"' "$html_file" | sed 's/.*content="\([^"]*\)".*/\1/')
  meta_tags=$(grep -oP '<meta\s+name="app:tags"\s+content="([^"]*)"' "$html_file" | sed 's/.*content="\([^"]*\)".*/\1/')
  meta_date=$(grep -oP '<meta\s+name="app:date"\s+content="([^"]*)"' "$html_file" | sed 's/.*content="\([^"]*\)".*/\1/')

  # Fallback: use directory name and first <h1>
  [ -z "$meta_name" ] && meta_name="$app_name"
  [ -z "$meta_desc" ] && meta_desc=$(grep -oP '<h1[^>]*>\K[^<]+' "$html_file" | head -1)
  [ -z "$meta_desc" ] && meta_desc="A mini app built with an LLM"

  # Fallback date: use git log or today
  if [ -z "$meta_date" ]; then
    meta_date=$(git log -1 --format="%ai" -- "$html_file" 2>/dev/null | cut -d' ' -f1)
    [ -z "$meta_date" ] && meta_date=$(date +%Y-%m-%d)
  fi

  apps+=("{\"slug\":\"$app_name\",\"name\":\"$meta_name\",\"description\":\"$meta_desc\",\"tags\":\"$meta_tags\",\"date\":\"$meta_date\"}")
done

# Sort by date descending (newest first)
IFS=$'\n' sorted_apps=($(printf '%s\n' "${apps[@]}" | sort -t'"' -k10,10r))
unset IFS

# --- Write manifest.json ---
echo "[" > "$MANIFEST"
first=true
for app in "${sorted_apps[@]}"; do
  $first || echo "," >> "$MANIFEST"
  echo "  $app" >> "$MANIFEST"
  first=false
done
echo "]" >> "$MANIFEST"

echo "Wrote $MANIFEST (${#sorted_apps[@]} apps)"

# --- Write gallery index.html ---
cat > "$GALLERY" <<GALEOF
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <meta name="description" content="Mini apps and interactive tools built with LLMs" />
  <title>$GALLERY_TITLE — David Spatholt</title>
  <link rel="stylesheet" href="../assets/style.css" />
</head>
<body>
  <a href="#main" class="skip-link">Skip to main content</a>

  <header class="site-header" role="banner">
    <div class="site-header-inner">
      <a href="../index.html" class="site-logo">David <strong>Spatholt</strong></a>
      <button class="nav-toggle" aria-expanded="false" aria-controls="site-nav" aria-label="Toggle navigation">
        ☰ Menu
      </button>
      <nav class="site-nav" id="site-nav" role="navigation" aria-label="Main navigation">
        <ul>
          <li><a href="../index.html">Home</a></li>
          <li><a href="../about/index.html">About</a></li>
          <li><a href="../research/index.html">Research</a></li>
          <li><a href="../experience/index.html">Experience</a></li>
          <li><a href="../projects/index.html">Projects</a></li>
          <li><a href="index.html" aria-current="page">Apps</a></li>
          <li><a href="../blog/index.html">Blog</a></li>
        </ul>
      </nav>
    </div>
  </header>

  <main id="main">
    <section class="page-hero">
      <div class="wrap">
        <h1>$GALLERY_TITLE</h1>
        <p>Interactive tools and mini apps built with Gemini, Claude, and other LLMs. Push your HTML, the gallery updates itself.</p>
      </div>
    </section>

    <section aria-labelledby="gallery-heading">
      <div class="wrap">
        <div style="max-width:var(--max-w); margin:0 auto;">
          <div class="card-grid" id="app-grid">
GALEOF

for app in "${sorted_apps[@]}"; do
  slug=$(echo "$app" | grep -oP '"slug":"([^"]*)"' | sed 's/"slug":"//;s/"//')
  name=$(echo "$app" | grep -oP '"name":"([^"]*)"' | sed 's/"name":"//;s/"//')
  desc=$(echo "$app" | grep -oP '"description":"([^"]*)"' | sed 's/"description":"//;s/"//' | sed 's/"/\&quot;/g')
  tags=$(echo "$app" | grep -oP '"tags":"([^"]*)"' | sed 's/"tags":"//;s/"//')
  date_str=$(echo "$app" | grep -oP '"date":"([^"]*)"' | sed 's/"date":"//;s/"//')

  cat >> "$GALLERY" <<APPEOF
            <article class="card">
              <span class="card-date">${date_str}</span>
              <h3><a href="${slug}/index.html">${name}</a></h3>
              <p>${desc}</p>
APPEOF

  if [ -n "$tags" ]; then
    echo "              <div class=\"card-tags\">" >> "$GALLERY"
    IFS=',' read -ra taglist <<< "$tags"
    for tag in "${taglist[@]}"; do
      trimmed_tag=$(echo "$tag" | xargs)
      echo "                <span class=\"tag tag--gray\">${trimmed_tag}</span>" >> "$GALLERY"
    done
    echo "              </div>" >> "$GALLERY"
  fi

  echo "            </article>" >> "$GALLERY"
done

cat >> "$GALLERY" <<GALEOF
          </div>
        </div>
      </div>
    </section>
  </main>

  <footer class="site-footer" role="contentinfo">
    <div class="footer-inner">
      <div class="footer-brand">
        <a href="../index.html" class="site-logo">David <strong>Spatholt</strong></a>
        Program management, systems thinking, and clinical research operations.
      </div>
      <nav class="footer-col" aria-label="Site links">
        <h4>Site</h4>
        <ul>
          <li><a href="../about/index.html">About</a></li>
          <li><a href="../research/index.html">Research</a></li>
          <li><a href="../experience/index.html">Experience</a></li>
          <li><a href="../projects/index.html">Projects</a></li>
          <li><a href="index.html">Mini Apps</a></li>
          <li><a href="../blog/index.html">Blog</a></li>
        </ul>
      </nav>
      <nav class="footer-col" aria-label="GitHub links">
        <h4>GitHub</h4>
        <ul>
          <li><a href="https://github.com/dspacks">dspacks</a></li>
          <li><a href="https://github.com/dspacks/healthnow-radar">HealthNow Radar</a></li>
          <li><a href="https://github.com/dspacks/hn_scheduler">HN Scheduler</a></li>
          <li><a href="https://github.com/dspacks/sectograph-watchface">Sectograph</a></li>
          <li><a href="https://github.com/dspacks">more &rarr;</a></li>
        </ul>
      </nav>
    </div>
  </footer>

  <script src="../assets/nav.js"></script>
</body>
</html>
GALEOF

echo "Wrote $GALLERY"
