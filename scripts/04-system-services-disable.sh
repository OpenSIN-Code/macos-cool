#!/usr/bin/env bash
# 04-system-services-disable.sh — System-Level Services (Braucht SUDO).
# Skript zeigt nur die Befehle, fuehrt nichts selbst aus.
#
# Konsequenzen siehe SKILL.md §3.
# User fuehrt die Befehle in Terminal.app aus und gibt sein Mac-Passwort ein.

printf "=== macos-cool · SYSTEM SERVICES DISABLE (sudo + interactive) ===\n\n"

printf "Diese Befehle DEAKTIVIEREN oder LOESCHEN System-Services.\n"
printf "Folgendes wird empfohlen - jeder einzeln mit\n"
printf "Erklaerung der Konsequenz und rueckgaengig-Befehl.\n\n"

cat <<'EOF'

# =============================================================
# 1. Spotlite-Indizierung komplett AUS
#    Konsequenz: cmd+Space-Suche langsamer / Mail-Suche weg.
#    R\xC3\xBCckg\xC3\xA4ngig:  sudo mdutil -a -i on
# =============================================================
sudo mdutil -a -i off

# =============================================================
# 2. photoanalysisd DEAKTIVIEREN (Foto-AI / Face Recognition)
#    Konsequenz: Photos.app macht keine Personen-/Szenen-Tags mehr.
#    Beste Loesung VOR dem Aus: Photos.app > Einstellungen >
#    "Gesichtserkennung verwenden" aus.
#    R\xC3\xBCckg\xC3\xA4ngig:  sudo launchctl enable system/com.apple.photoanalysisd
# =============================================================
sudo launchctl disable system/com.apple.photoanalysisd

# =============================================================
# 3. Time Machine Auto-Backup AUS
#    Konsequenz: keine lokalen APFS-Snapshots mehr, kein Auto-Backup.
#    Bei manueller Disk weiter Backup moeglich ueber Finder.
#    R\xC3\xBCckg\xC3\xA4ngig:  sudo tmutil enable
# =============================================================
sudo tmutil disable

# =============================================================
# 4. Telemetrie / Analytics AUS
#    Konsequenz: macOS schickt keine anonymisierten Usage-Stats
#    mehr an Apple.
#    R\xC3\xBCckg\xC3\xA4ngig:  sudo launchctl enable system/com.apple.analyticsd
# =============================================================
sudo launchctl disable system/com.apple.analyticsd
sudo launchctl disable system/com.apple.dprivacyd
sudo launchctl disable system/com.apple.SubmitDiagInfo
defaults write com.apple.CrashReporter AutoSubmit -bool false
defaults write com.apple.CrashReporter SendAnonymousData -bool false

# =============================================================
# 5. Adobe ARMDC / ARMDCHelper SYSTEM-Pfade loeschen
#    Konsequenz: Adobe-Apps (Acrobat, Photoshop) verlieren Cloud-Update.
#    R\xC3\xBCckg\xC3\xA4ngig:  Adobe CC neu installieren.
# =============================================================
sudo rm -f /Library/LaunchAgents/com.adobe.ARMDCHelper.*.plist
sudo rm -f /Library/LaunchDaemons/com.adobe.ARMDC.Communicator.plist
sudo rm -f /Library/LaunchDaemons/com.adobe.ARMDC.SMJobBlessHelper.plist

# =============================================================
# 6. TotalAV / Generic AV DEAKTIVIEREN
#    Konsequenz: AV laeuft nicht mehr. macOS hat eigenen
#    (kostenlosen + automatischen) XProtect/Gatekeeper.
#    R\xC3\xBCckg\xC3\xA4ngig:  TotalAV neu installieren.
# =============================================================
sudo launchctl disable system/net.protected.macos.AVHelper 2>/dev/null || true
sudo rm -f /Library/LaunchDaemons/net.protected.macos.AVHelper.plist

# =============================================================
# 7. iCloud Drive Background Sync DEAKTIVIEREN
#    Konsequenz: KEIN iCloud-Drive mehr aktiv.
#    ACHTUNG: kann Datenverlust bei unsyncronisierten Files geben -
#    Backup/Sync-DB lokal sichern VORHER.
#    R\xC3\xBCckg\xC3\xA4ngig:  System Settings > Apple-ID > iCloud an
# =============================================================
sudo launchctl disable system/com.apple.cloudd 2>/dev/null || true
sudo launchctl disable system/com.apple.bird 2>/dev/null    || true   # iCloud-Drive IO

# =============================================================
# 8. Login-Items (AutoLaunch) holen + ggfs. abklemmen
#    Konsequenz: pro App entscheiden.
# =============================================================
osascript -e 'tell application "System Events" to get the name of every login item'
# und ABBLDEN:
# osascript -e 'tell application "System Events" to delete login item "<NAME>"'

EOF
echo ""
echo "Jeder Block oben ist in Terminal.app zu kopieren + RETURN + bei sudo die PW-Eingabe."
echo "Alle Befehle sind reversibel - SKILL.md \xC2\xA73/§9 fuehrt alle rueckgaengig-Befehle."
