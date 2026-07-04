#!/usr/bin/env bash
# 05-chrome-memory-saver.sh — setzt Chrome's Memory Saver AN, Energy Saver AUS, in jedem Profil.
# Voraussetzung: Chrome MUSS geschlossen sein (sonst ueberschreibt Chrome die Preferences-Datei).
#
# Vor dem Lauf:
#   osascript -e 'tell application "Google Chrome" to quit'
#   # oder manuell: cmd+Q auf jedem Chrome-Fenster
#
# Nach dem Lauf:
#   open -a "Google Chrome"
#
# Pruefe: chrome://settings/performance

set -euo pipefail

H="$HOME"
CHROME_BASE="$H/Library/Application Support/Google/Chrome"

if /bin/ps aux | /usr/bin/grep -E "Google Chrome" | /usr/bin/grep -v grep >/dev/null; then
  echo "===== ACHTUNG ====="
  echo "Chrome laeuft noch. Bitte zuerst Chrome beenden:"
  echo "  osascript -e 'tell application \"Google Chrome\" to quit'"
  echo "  # oder cmd+Q auf jedem Fenster"
  # Don't exit — let it run if user wants to force-edit with the running process.
  echo ""
  printf "Trotzdem fortfahren (Prefs koennten von Chrome ueberschrieben werden)? (y/N): "
  read -r ans
  [ "$ans" = "y" ] || [ "$ans" = "Y" ] || exit 1
fi

if [ ! -d "$CHROME_BASE" ]; then
  echo "Kein Chrome-Profil-Verzeichnis: $CHROME_BASE"
  exit 1
fi

echo "=== Chrome Profile vorhanden ==="
/bin/ls "$CHROME_BASE/" 2>/dev/null | /usr/bin/grep -E "^(Default|Profile)" | /usr/bin/head -20

# Find preferences.json in jedem Profil
echo ""
echo "=== Setze Memory Saver AN, Energy Saver AUS in alle Profile-Prefs ==="

count=0
for prefs in "$CHROME_BASE/Default/Preferences" "$CHROME_BASE/Profile "*/Preferences ; do
  [ -f "$prefs" ] || continue
  /usr/bin/python3 - "$prefs" <<'PY'
import json
import sys
p = sys.argv[1]
try:
    with open(p) as fh:
        d = json.load(fh)
except Exception as e:
    print(f"  [skip] kann nicht lesen: {p}: {e}")
    sys.exit(0)

d.setdefault('performance', {})
d['performance'].setdefault('memory_saver_mode', {})
d['performance']['memory_saver_mode']['enabled'] = True
d['performance'].setdefault('energy_saver_mode', {})
d['performance']['energy_saver_mode']['enabled'] = False
# Disable labeled thresholds where possible
d['performance']['energy_saver_mode'].setdefault('discharge_threshold', 0)

with open(p, 'w') as fh:
    json.dump(d, fh, indent=2)
print(f"  [OK] {p}")
PY
  count=$(( count + 1 ))
done

echo ""
echo "=== Fertig in $count Profil(en) ==="
echo ""
echo "Starte Chrome und pruefe:"
echo "  open -a 'Google Chrome'"
echo "  # URL: chrome://settings/performance"
echo "  #     Memory Saver sollte 'AN' sein"
echo "  #     Energy Saver sollte 'AUS' sein"
