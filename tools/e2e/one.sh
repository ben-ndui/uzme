#!/usr/bin/env bash
# Un seul flow, sur un simulateur déjà démarré avec l'app installée (via
# `fvm flutter run -d <udid> --dart-define=USE_EMULATORS=true`).
#
# ⚠️ `flutter build ios --simulator` est CASSÉ sur cette machine (bug du
# toolchain Xcode, confirmé pré-existant et indépendant de ce chantier —
# cf. commentaire dans build.sh) : pas d'étape d'installation séparée ici,
# contrairement au gabarit taxiboat. `flutter run` laisse déjà une vraie
# app installée ; ce script relance juste CETTE app (`launchApp` dans
# chaque flow s'en charge).
#
# Usage : tools/e2e/one.sh <udid> <nom-du-flow>
set -uo pipefail
cd "$(dirname "$0")/../.."
UDID="$1"; FLOW="$2"

xcrun simctl boot "$UDID" 2>/dev/null
for _ in $(seq 1 60); do
  xcrun simctl list devices | grep -q "$UDID).*Booted" && { sleep 2; break; }
  sleep 2
done

maestro --device "$UDID" test "tools/e2e/flows/$FLOW.yaml" 2>&1 | grep -vE "^WARNING|^\s+at "
