#!/usr/bin/env bash
# index-blog.sh — Scan docs/blog/ for posts and regenerate:
#   1. docs/blog/manifest.json  (machine-readable index)
#   2. docs/blog/index.html     (human-readable blog index)
#
# Each post lives in a subdirectory under docs/blog/ with index.html.
# Metadata is read from <meta> tags in the HTML <head>:
#
#   <meta name="blog:title"   content="Post Title">
#   <meta name="blog:date"    content="2026-06-18">
#   <meta name="blog:tags"    content="research,health">
#   <meta name="blog:excerpt" content="Short summary...">
#   <meta name="blog:author"  content="David Spatholt">
#
# If title/excerpt are missing, they're inferred from filename and first <h1>/<p>.
# Scripts dir and build files (index.sh, manifest.json, index.html) in blog/ root are skipped.

BLOG_DIR="docs/blog"
MANIFEST="$BLOG_DIR/manifest.json"
GALLERY="$BLOG_DIR/index.html"
GALLERY_TITLE="Blog"

# Ensure blog dir exists
mkdir -p "$BLOG_DIR"

posts=()
for post_dir in "$BLOG_DIR"/*/; do
  [ -d "$post_dir" ] || continue
  slug=$(basename "$post_dir")

  html_file="${post_dir}index.html"
  [ -f "$html_file" ] || continue

  # Skip hidden drafts/templates/noindex pages
  if grep -qE 'class="[^"]*(is-template|is-placeholder|is-draft)|data-(status|visibility)="(template|placeholder|draft)"|name="robots"\s+content="noindex' "$html_file"; then
    continue
  fi

  # Extract metadata from <meta> tags
  meta_title=$(grep -oP '<meta\s+name="blog:title"\s+content="([^"]*)"' "$html_file" | sed 's/.*content="\([^"]*\)".*/\1/')
  meta_date=$(grep -oP '<meta\s+name="blog:date"\s+content="([^"]*)"' "$html_file" | sed 's/.*content="\([^"]*\)".*/\1/')
  meta_tags=$(grep -oP '<meta\s+name="blog:tags"\s+content="([^"]*)"' "$html_file" | sed 's/.*content="\([^"]*\)".*/\1/')
  meta_excerpt=$(grep -oP '<meta\s+name="blog:excerpt"\s+content="([^"]*)"' "$html_file" | sed 's/.*content="\([^"]*\)".*/\1/')
  meta_author=$(grep -oP '<meta\s+name="blog:author"\s+content="([^"]*)"' "$html_file" | sed 's/.*content="\([^"]*\)".*/\1/')

  # Fallbacks
  [ -z "$meta_title" ] && meta_title=$(grep -oP '<h1[^>]*>\K[^<]+' "$html_file" | head -1)
  [ -z "$meta_title" ] && meta_title="$slug"
  [ -z "$meta_excerpt" ] && meta_excerpt=$(grep -oP '<p[^>]*>\K[^<]+' "$html_file" | head -1)
  [ -z "$meta_excerpt" ] && meta_excerpt="A blog post."
  [ -z "$meta_author" ] && meta_author="David Spatholt"

  # Fallback date: use git log or today
  if [ -z "$meta_date" ]; then
    meta_date=$(git log -1 --format="%ai" -- "$html_file" 2>/dev/null | cut -d' ' -f1)
    [ -z "$meta_date" ] && meta_date=$(date +%Y-%m-%d)
  fi

  posts+=("{\"slug\":\"$slug\",\"title\":\"$meta_title\",\"date\":\"$meta_date\",\"tags\":\"$meta_tags\",\"excerpt\":\"$meta_excerpt\",\"author\":\"$meta_author\"}")
done

# Sort by date descending (newest first)
IFS=$'\n' sorted_posts=($(printf '%s\n' "${posts[@]}" | sort -t'"' -k10,10r))
unset IFS

# --- Write manifest.json ---
echo "[" > "$MANIFEST"
first=true
for post in "${sorted_posts[@]}"; do
  $first || echo "," >> "$MANIFEST"
  echo "  $post" >> "$MANIFEST"
  first=false
done
echo "]" >> "$MANIFEST"

echo "Wrote $MANIFEST (${#sorted_posts[@]} posts)"

# --- Write blog index.html ---
cat > "$GALLERY" <<GALEOF
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <meta name="description" content="Blog — David Spatholt" />
  <title>Blog — David Spatholt</title>
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
          <li><a href="../apps/index.html">Apps</a></li>
          <li><a href="index.html" aria-current="page">Blog</a></li>
        </ul>
      </nav>
    </div>
  </header>

  <main id="main">
    <section class="page-hero">
      <div class="wrap">
        <h1>Blog</h1>
        <p>Notes, deep dives, and things I'm thinking about</p>
      </div>
    </section>

    <section aria-labelledby="blog-heading">
      <div class="wrap">
        <div style="max-width:var(--max-w); margin:0 auto;">
          <div class="blog-list" id="blog-posts">
GALEOF

for post in "${sorted_posts[@]}"; do
  slug=$(echo "$post" | grep -oP '"slug":"([^"]*)"' | sed 's/"slug":"//;s/"//')
  title=$(echo "$post" | grep -oP '"title":"([^"]*)"' | sed 's/"title":"//;s/"//')
  date_str=$(echo "$post" | grep -oP '"date":"([^"]*)"' | sed 's/"date":"//;s/"//')
  tags=$(echo "$post" | grep -oP '"tags":"([^"]*)"' | sed 's/"tags":"//;s/"//')
  excerpt=$(echo "$post" | grep -oP '"excerpt":"([^"]*)"' | sed 's/"excerpt":"//;s/"//' | sed 's/"/\&quot;/g')
  author=$(echo "$post" | grep -oP '"author":"([^"]*)"' | sed 's/"author":"//;s/"//')

  cat >> "$GALLERY" <<POSTEOF
            <article class="blog-card">
              <div class="blog-card-meta">
                <time datetime="${date_str}">${date_str}</time>
                <span class="blog-card-author">${author}</span>
              </div>
              <h2><a href="${slug}/index.html">${title}</a></h2>
              <p>${excerpt}</p>
POSTEOF

  if [ -n "$tags" ]; then
    echo "              <div class=\"blog-card-tags\">" >> "$GALLERY"
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
      <nav class="footer-col" aria-label="Quick links">
        <h4>Site</h4>
        <ul>
          <li><a href="../about/index.html">About</a></li>
          <li><a href="../research/index.html">Research</a></li>
          <li><a href="../experience/index.html">Experience</a></li>
          <li><a href="../projects/index.html">Projects</a></li>
          <li><a href="../apps/index.html">Mini Apps</a></li>
          <li><a href="index.html">Blog</a></li>
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
