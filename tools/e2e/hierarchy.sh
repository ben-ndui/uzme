#!/usr/bin/env bash
# Libellés réellement exposés à l'automate, sur le simulateur donné.
#
# Sans ça on devine les sélecteurs, et « Element not found » ne dit jamais ce
# qu'il y avait à l'écran.
set -uo pipefail
maestro --device "$1" hierarchy 2>/dev/null | python3 -c "
import sys, json
raw = sys.stdin.read()
i = raw.find('{')
if i < 0:
    print('hiérarchie illisible — app au premier plan ?'); sys.exit(1)
h = json.loads(raw[i:])
vus, out = set(), []
def parcours(n):
    a = n.get('attributes', {})
    for cle in ('text', 'hintText', 'accessibilityText'):
        v = (a.get(cle) or '').strip()
        if v and v not in vus:
            vus.add(v); out.append(v)
    for c in (n.get('children') or []):
        parcours(c)
parcours(h)
bruit = ('Aucun signal', 'Données cellulaires', 'SSID', 'Aucune recharge',
         'Charge de la batterie')
for t in out:
    if not t.startswith(bruit):
        print(repr(t))
"
