#!/usr/bin/env bash
# build-pptx.sh — convert the markdown deck into an EDITABLE .pptx via pandoc.
# Upload the result to Google Drive → right-click → "Open with Google Slides"
# and every slide is native, editable text (not images). Speaker notes land in
# the notes pane.
#
# Usage:
#   ./build-pptx.sh                 # slides/  -> wargames-secret-manager.pptx
#   ./build-pptx.sh longer-version wargames-full.pptx
set -euo pipefail

DIR="${1:-slides}"
OUT="${2:-wargames-secret-manager.pptx}"

if ! command -v pandoc >/dev/null 2>&1; then
  echo "pandoc is not installed. Run:  brew install pandoc" >&2
  exit 1
fi

TMP="$(mktemp).md"

# Assemble all slides, then:
#  - drop the standalone '---' separators (pandoc breaks slides on the '#' titles)
#  - turn each "> **Notes:** ... " blockquote into a pandoc "::: notes" div
#    (which pandoc puts into the PowerPoint speaker-notes pane)
#  - leave any OTHER blockquote (e.g. the WOPR quote) as on-slide content
{
  for f in "$DIR"/*.md; do cat "$f"; echo; done
} | awk '
  BEGIN { innote = 0 }
  /^---$/                            { if (innote) { print ":::"; innote = 0 } next }
  /^[[:space:]]*> \*\*Notes:\*\*/    { print ""; print "::: notes"; innote = 1; next }
  {
    if (innote) {
      if ($0 ~ /^[[:space:]]*>/) {
        line = $0; sub(/^[[:space:]]*> ?/, "", line); print line; next
      } else {
        print ":::"; print ""; innote = 0
      }
    }
    print
  }
  END { if (innote) print ":::" }
' > "$TMP"

pandoc "$TMP" -o "$OUT" --slide-level=1
rm -f "$TMP"

echo "✅ wrote $OUT"
echo "   Next: upload it to Google Drive, right-click → Open with Google Slides."
