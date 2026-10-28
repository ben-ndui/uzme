#!/usr/bin/env bash
# Campagne E2E — contre les ÉMULATEURS Firebase, jamais la production.
#
# État au 28/10/2026 : UN SEUL flow prouvé (01-connexion). Les 5 autres
# visés (inscription, réservation de session, suppression de compte, ajout
# de service, favoris) restent à écrire — voir le fichier de flow 01 pour
# les pièges déjà rencontrés et leurs parades (zone tactile du champ email
# surdimensionnée, feuille DRAGGABLE qui lit un swipe comme un
# agrandissement, "Se connecter" seulement mesurable clavier fermé).
#
# Usage : tools/e2e/run.sh <udid>
# (l'app doit déjà tourner sur ce simulateur via :
#   fvm flutter run -d <udid> --dart-define=USE_EMULATORS=true
#  — voir build.sh pour pourquoi `flutter build` ne marche pas ici.)
set -uo pipefail
cd "$(dirname "$0")/../.."
UDID="${1:?Usage: tools/e2e/run.sh <udid>}"

FLOWS=("01-connexion")

echo "▸ Émulateurs Firebase"
if ! curl -s "http://127.0.0.1:8080" >/dev/null 2>&1; then
  echo "  démarrage…"
  firebase emulators:start --only auth,firestore,storage --project uzme-app \
      > /tmp/uzme_e2e_emulators.log 2>&1 &
  for _ in $(seq 1 60); do
    grep -q "All emulators ready" /tmp/uzme_e2e_emulators.log 2>/dev/null && break
    sleep 2
  done
  grep -q "All emulators ready" /tmp/uzme_e2e_emulators.log || {
    echo "  ✗ émulateurs injoignables — voir /tmp/uzme_e2e_emulators.log"; exit 1; }
fi
echo "  ✔ prêts"

echo "▸ Jeu de données"
(cd tools/e2e && node seed.js) | sed 's/^/  /' || exit 1

echo "▸ Flows"
FAILED=0
for flow in "${FLOWS[@]}"; do
  if tools/e2e/one.sh "$UDID" "$flow" > "/tmp/e2e-$flow.log" 2>&1; then
    echo "  ✔ $flow"
  else
    echo "  ✗ $flow — /tmp/e2e-$flow.log"
    FAILED=$((FAILED + 1))
  fi
done

echo
if [[ $FAILED -eq 0 ]]; then
  echo "▸ ${#FLOWS[@]} flow(s) joué(s), tous verts."
else
  echo "▸ $FAILED échec(s) sur ${#FLOWS[@]} flow(s)."
fi
exit $FAILED
