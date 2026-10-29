#!/usr/bin/env bash
#
# Build + upload TestFlight depuis CE Mac — zéro minute de runner macOS
# GitHub Actions (0,062 $/min, ~34 min par build sur ce repo).
#
# Reproduit exactement les étapes de .github/workflows/ios-deploy.yml,
# sans passer par Actions. Les secrets ne vivent nulle part dans ce repo :
# ils doivent être déjà exportés dans TON shell avant de lancer ce script
# (ASC_KEY_ID, ASC_ISSUER_ID, ASC_KEY_CONTENT, MATCH_GIT_URL,
# MATCH_PASSWORD — voir `gh secret list` pour la liste complète des noms,
# jamais des valeurs).
#
# Usage : scripts/deploy-ios-local.sh [build_number]
#   (sans argument, le numéro de build vient de `git rev-list --count HEAD`,
#   comme GITHUB_RUN_NUMBER le ferait côté Actions — à ajuster si ça entre
#   en collision avec un build déjà uploadé.)
set -euo pipefail
cd "$(dirname "$0")/.."

REQUIRED_VARS=(ASC_KEY_ID ASC_ISSUER_ID ASC_KEY_CONTENT MATCH_GIT_URL MATCH_PASSWORD)
MANQUANTES=()
for v in "${REQUIRED_VARS[@]}"; do
  [ -z "${!v:-}" ] && MANQUANTES+=("$v")
done
if [ ${#MANQUANTES[@]} -gt 0 ]; then
  echo "✗ Variables manquantes : ${MANQUANTES[*]}" >&2
  echo "  Les NOMS existent déjà comme secrets GitHub (gh secret list) —" >&2
  echo "  les VALEURS ne sont récupérables que depuis là où tu les as" >&2
  echo "  stockées toi-même (le .p8 App Store Connect, le mot de passe Match)." >&2
  exit 1
fi

if ! bundle exec fastlane --version >/dev/null 2>&1; then
  echo "✗ \`bundle exec fastlane\` ne répond pas." >&2
  echo "  Le Ruby système (2.6) est trop vieux pour ce Gemfile.lock —" >&2
  echo "  gem install bundler:2.5.23   (ou passer par rbenv/homebrew ruby)" >&2
  exit 1
fi

BUILD_NUMBER="${1:-$(git rev-list --count HEAD)}"
VERSION="$(grep '^version:' pubspec.yaml | sed 's/version: *//;s/+.*//')"

echo "▸ Version $VERSION, build #$BUILD_NUMBER"

echo "▸ Pods"
(cd ios && bundle exec pod install --repo-update)

echo "▸ Signing (Fastlane Match)"
bundle exec fastlane ios setup_signing

echo "▸ Build IPA"
flutter build ipa --release \
  --build-number="$BUILD_NUMBER" \
  --export-options-plist=ios/ExportOptions.plist

IPA_PATH="$(find build/ios/ipa -name '*.ipa' | head -1)"
[ -z "$IPA_PATH" ] && { echo "✗ Aucun .ipa trouvé dans build/ios/ipa" >&2; exit 1; }
echo "  $IPA_PATH"

echo "▸ Notes de version (RELEASE_NOTES.md, section v$VERSION)"
RELEASE_NOTES_FR="$(./scripts/extract_release_notes.sh "$VERSION" FR 2>/dev/null || echo "")"
RELEASE_NOTES_EN="$(./scripts/extract_release_notes.sh "$VERSION" EN 2>/dev/null || echo "")"
export RELEASE_NOTES_FR RELEASE_NOTES_EN

echo "▸ Upload TestFlight"
IPA_PATH="$IPA_PATH" bundle exec fastlane ios deploy

echo
echo "✔ Build #$BUILD_NUMBER uploadé sur TestFlight — zéro minute Actions consommée."
