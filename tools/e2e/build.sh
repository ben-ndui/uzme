#!/usr/bin/env bash
# Build de l'app pour le harnais E2E — toujours avec USE_EMULATORS=true, sinon
# l'app viserait la production par erreur.
#
# ⚠️ CASSÉ sur cette machine au 28/10/2026 : `flutter build ios --simulator`
# échoue avec "Binary ... does not contain architectures arm64 x86_64" alors
# que `lipo -info` montre bien les deux archs (juste dans l'ordre inverse) —
# bug du toolchain Xcode, confirmé PRÉ-EXISTANT en reproduisant à l'identique
# sur un `flutter build` sans aucun des changements de ce chantier.
#
# Contournement utilisé pour valider le socle (01-connexion) : lancer l'app
# via `fvm flutter run -d <udid> --dart-define=USE_EMULATORS=true` à la
# place — un chemin de build différent qui n'est pas touché par ce bug, et
# qui installe une vraie app sur laquelle `tools/e2e/one.sh` peut enchaîner
# les flows sans reconstruire. À régler avant d'automatiser `run.sh` en une
# seule commande (nettoyer DerivedData, ou reproduire avec `flutter doctor`
# pour isoler la cause exacte).
set -euo pipefail
cd "$(dirname "$0")/../.."

FLUTTER="${FLUTTER:-fvm flutter}"

echo "▸ Build iOS simulateur (émulateurs Firebase)…"
$FLUTTER build ios --simulator --debug --dart-define=USE_EMULATORS=true
