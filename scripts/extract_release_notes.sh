#!/usr/bin/env bash
#
# Extracts the release notes for a given version from RELEASE_NOTES.md
# and prints them to stdout. Used by android-deploy.yml and
# ios-deploy.yml to feed Fastlane with per-locale release notes.
#
# Convention in RELEASE_NOTES.md:
#
#     ## v1.5.24
#
#     ### FR
#     Texte court FR (≤500 chars Play Store, ≤4000 App Store).
#
#     ### EN
#     Short EN text.
#
#     ### SG
#     Texte court Sango (in-app what's-new only, pas une locale store).
#
# Usage:
#     ./scripts/extract_release_notes.sh <version> <locale>
#     ./scripts/extract_release_notes.sh 1.5.24 FR
#
# Exits 0 with empty stdout if the section or locale isn't found —
# Fastlane will skip the release_notes upload gracefully.

set -euo pipefail

VERSION="${1:-}"
LOCALE="${2:-}"

if [ -z "$VERSION" ] || [ -z "$LOCALE" ]; then
  echo "Usage: $0 <version> <locale>" >&2
  exit 1
fi

if [ ! -f RELEASE_NOTES.md ]; then
  exit 0
fi

# `## v1.5.24` may have an optional "— date" suffix. Match prefix then
# stop at the next `## v` heading. Inside the version block, capture
# only the requested locale heading (`### FR`).
awk -v ver="v${VERSION}" -v loc="### ${LOCALE}" '
  $0 ~ "^## "ver"( |$)" { in_version=1; next }
  in_version && /^## v/ { exit }
  in_version && $0 == loc { in_locale=1; next }
  in_version && /^### / && $0 != loc { in_locale=0 }
  in_version && in_locale { print }
' RELEASE_NOTES.md
