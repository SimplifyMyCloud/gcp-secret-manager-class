#!/usr/bin/env bash
# build-deck.sh — assemble a slide folder into ONE import-ready markdown file.
#
# It concatenates NN-*.md in order, inserts a `---` slide break between modules,
# and converts each "> **Notes:** ..." blockquote into an <!-- HTML comment -->.
# Marp and md2googleslides both treat HTML comments as SPEAKER NOTES, so on
# import the notes land in the notes pane instead of on the slide.
#
# Usage:
#   ./build-deck.sh slides          > deck.import.md        # the ~25-30 min deck
#   ./build-deck.sh longer-version  > deck-full.import.md   # the full deck
#
# Then, e.g.:
#   brew install marp-cli && marp deck.import.md --pptx     # -> upload to Google Slides
#   # or: md2gslides deck.import.md                          # pushes straight to Slides
set -euo pipefail
DIR="${1:-slides}"
[ -d "$DIR" ] || { echo "no such deck folder: $DIR" >&2; exit 1; }

first=1
for f in "$DIR"/*.md; do
  [ $first -eq 1 ] || printf '\n---\n\n'   # slide break between modules
  cat "$f"
  first=0
done | awk '
  function flush(   i) {
    if (n == 0) return
    print "<!--"
    for (i = 0; i < n; i++) print notes[i]
    print "-->"
    n = 0
  }
  /^[[:space:]]*>/ {                 # a blockquote line = speaker note
    line = $0
    sub(/^[[:space:]]*> ?/, "", line)
    sub(/^\*\*Notes:\*\* */, "", line)          # drop the "**Notes:**" label
    sub(/^\*\*Speaker notes:\*\* */, "", line)  # (full deck uses this label)
    notes[n++] = line
    innote = 1
    next
  }
  {
    if (innote) { flush(); innote = 0 }
    print
  }
  END { if (innote) flush() }
'
