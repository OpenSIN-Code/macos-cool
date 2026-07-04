#!/usr/bin/env bash
# 06-undo-all.sh — Reverse-Befehle fuer macos-cool.
# Versucht, alle deaktivierten Services wieder zu starten.
#
# Was NICHT rueckgaengig zu machen ist:
#   - geloeschte Browser-Caches / Dev-Caches (werden automatisch neu gefuellt)
#   - geloeschte Application-Support (App muss neu installiert werden)
#   - geleerte Trash (irreversibel, vorher APFS-Snapshot machen!)
#
# Was rueckgaengig geht (siehe Befehle unten):

printf "=== macos-cool · UNDO ALL ===\n\n"
printf "Diese Befehle aktivieren alle deaktivierten Services wieder.\n"
printf "SUDO-Passwort noetig fue launchctl-Enable-Befehle.\n"
printf "Loeschungen von Application-Support-Caches sind HIER NICHT enthalten\n"
printf "(kann nicht rueckgaengig gemacht werden ohne Backup).\n\n"

cat <<'EOF'

# Spotlite -WIEDER- ein
sudo mdutil -a -i on
# (Re-Indizierung laeuft im Hintergrund, kann Stunden dauern.)

# photoanalysisd -WIEDER- ein
sudo launchctl enable system/com.apple.photoanalysisd

# Time Machine -WIEDER- ein
sudo tmutil enable

# analyticsd / dprivacyd - wieder ein
sudo launchctl enable system/com.apple.analyticsd
sudo launchctl enable system/com.apple.dprivacyd
sudo launchctl enable system/com.apple.SubmitDiagInfo

# iCloud-Sync wieder ein
sudo launchctl enable system/com.apple.cloudd 2>/dev/null || true
sudo launchctl enable system/com.apple.bird 2>/dev/null    || true

# CrashReporter wieder ein (optional)
defaults write com.apple.CrashReporter AutoSubmit -bool true
defaults write com.apple.CrashReporter SendAnonymousData -bool true

# Adobe ARM Re-install: am einfachsten Adobe Creative Cloud neu installieren.

# LaunchAgents neu setzen ist nicht trivial; einfach die Apps neu installieren
# (Microsoft Office, MEGA, Adobe CC, JetBrains Toolbox, ...).

EOF

echo ""
echo "=== Mini-Cleanup Dev-Caches (Reversible weil regenerierbar) ==="
echo ""
echo "Auch moeglich: R\xC3\xBCcksetzen der Chrome Performance Settings:"
cat <<'EOF'

# Chrome wieder Standard
/usr/bin/python3 - <<'PY'
import json, glob
for prefs in glob.glob('$HOME/Library/Application Support/Google/Chrome/Default/Preferences') + \
             glob.glob('$HOME/Library/Application Support/Google/Chrome/Profile */Preferences'):
    try:
        d = json.loads(open(prefs).read())
        d.setdefault('performance', {})
        d['performance'].setdefault('memory_saver_mode', {})['enabled'] = False
        d['performance'].setdefault('energy_saver_mode', {})['enabled'] = True
        open(prefs, 'w').write(json.dumps(d))
    except Exception as e:
        pass
PY
EOF

printf "\n=== Done. Restart empfohlen ===\n"
printf "  sudo shutdown -r +5\n"
