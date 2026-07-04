#!/usr/bin/env bash
# 08-deep-cleanup.sh — orchestriert §15-§21 vom SKILL.md.
# SavedState / Logs / Personal-Apps / Notification / Fonts / QuickLook.
# pmset Snapshot + Vorschlag (User fuehrt sudo-Befehle selbst aus).
#
# Usage:
#   bash scripts/08-deep-cleanup.sh [profile] [--auto|--yes]
#
# Profile-Default: developer
# Mode-Default:    interactive

set -euo pipefail

PROFILE="${1:-developer}"
MODE="interactive"
for a in "$@"; do
  case "$a" in
    --auto)     MODE="auto" ;;
    --yes)      MODE="auto" ;;
    --profile=*) PROFILE="${a#--profile=}" ;;
  esac
done

H="$HOME"
YES=0
[ "$MODE" = "auto" ] && YES=1

header() { printf "\n=== %s ===\n" "$1"; }

casual_ask() {
  local msg="$1"
  if [ "$YES" = "1" ]; then return 0; fi
  printf "  %s [y/N]: " "$msg"
  read -r ans
  case "$ans" in
    y|Y|yes|Yes) return 0 ;;
    *)           return 1 ;;
  esac
}

case "$PROFILE" in
  developer-minimal|developer|power-user|privacy-paranoid) ;;
  *) PROFILE="developer" ;;
esac

header "macos-cool · 08-deep-cleanup · profile=$PROFILE"

# ========================================================
# 1. pmset Snapshot (read-only)
# ========================================================
header "[1/8] pmset — current state (read-only)"
pmset -g 2>/dev/null
echo ""
echo "Empfohlene sudo-Befehle (nicht ausgefuehrt, User kopiert sie separat):"
printf "  %s\n" "sudo pmset -womp 0              # Wake-on-LAN aus"
printf "  %s\n" "sudo pmset -powernap 0          # Power Nap aus"
printf "  %s\n" "sudo pmset -networkreachabilityoff 1   # kein Wake fuer Net"
printf "  %s\n" "sudo pmset -standbydelay 43200  # Standby nach 12h statt 1h"
printf "  %s\n" "sudo pmset displaysleep 10 disksleep 15 sleep 20"

# ========================================================
# 2. Saved Application State
# ========================================================
header "[2/8] Saved Application State (~/$USER/Library/Saved Application State/)"
SAS_DIR="$H/Library/Saved Application State"
if [ -d "$SAS_DIR" ]; then
  total_bytes=0
  printf "%-65s %8s\n" "PATH" "GROESSE"
  /usr/bin/printf "%.s-" {1..80}; echo
  for d in "$SAS_DIR/"*; do
    [ -d "$d" ] || continue
    sz_bytes=$(/usr/bin/du -sb "$d" 2>/dev/null | /usr/bin/awk '{print $1}')
    sz_h=$(/usr/bin/du -sh "$d" 2>/dev/null | /usr/bin/awk '{print $1}')
    name=$(basename "$d")
    printf "%-65s %8s\n" "$name" "$sz_h"
    total_bytes=$(( total_bytes + sz_bytes ))
  done
  total_mb=$(( total_bytes / 1024 / 1024 ))
  echo ""
  echo "TOTAL: ${total_mb} MB"
  echo ""
  if casual_ask "Alle SavedApplicationStates loeschen? (UI reset, keine Daten weg)"; then
    /usr/bin/find "$SAS_DIR" -mindepth 1 -depth -delete 2>/dev/null
    echo "  [$OK] entfernt."
  else
    echo "  [skip] Selective loeschen manuell mit: rm -rf <App>.savedState"
  fi
else
  echo "Kein SavedApplicationState vorhanden."
fi

# ========================================================
# 3. Logs Cleanup (old + .gz)
# ========================================================
header "[3/8] User-Logs ~/Library/Logs/ (alte .gz + .old)"
LOGS_DIR="$H/Library/Logs"
if [ -d "$LOGS_DIR" ]; then
  total_lo=$(/usr/bin/du -sh "$LOGS_DIR" 2>/dev/null | /usr/bin/awk '{print $1}')
  echo "Gesamtgroesse: $total_lo"
  candidates=$(/usr/bin/find "$LOGS_DIR" -mtime +30 \( -name "*.old" -o -name "*.gz" -o -name "*.log.*.*" \) -type f 2>/dev/null | /usr/bin/wc -l)
  echo "Kandidaten (.old/.gz/.log.X.X > 30d): $candidates Files"
  if casual_ask "Alte Logs / .gz / .old loeschen?"; then
    /usr/bin/find "$LOGS_DIR" -mtime +30 \( -name "*.old" -o -name "*.gz" -o -name "*.log.*.*" \) -delete 2>/dev/null
    /usr/bin/find "$LOGS_DIR" -type f -mtime +180 -delete 2>/dev/null
    after=$(/usr/bin/du -sh "$LOGS_DIR" 2>/dev/null | /usr/bin/awk '{print $1}')
    echo "  [OK] nachher: $after"
  fi
fi

# ========================================================
# 4. Personal App Caches
# ========================================================
header "[4/8] Personal-App-Caches (regenerieren sich automatisch)"
declare -a APPS=(
  "$H/Library/Caches/com.spotify.client"
  "$H/Library/Application Support/Slack/Cache"
  "$H/Library/Application Support/Slack/Code Cache"
  "$H/Library/Application Support/Slack/GPUCache"
  "$H/Library/Application Support/Slack/logs"
  "$H/Library/Application Support/discord/Cache"
  "$H/Library/Application Support/discord/Code Cache"
  "$H/Library/Application Support/discord/GPUCache"
  "$H/Library/Application Support/zoom.us/logs"
  "$H/Library/Caches/com.whatsapp.desktop"
  "$H/Library/Caches/com.microsoft.teams"
  "$H/Library/Caches/io.telegram.TelegramDesktop"
  "$H/Library/Caches/com.operasoftware.Opera"
  "$H/Library/Caches/com.google.GoogleDriveFS"
)
total_bytes=0
for p in "${APPS[@]}"; do
  if [ -e "$p" ]; then
    sz=$(/usr/bin/du -sb "$p" 2>/dev/null | /usr/bin/awk '{print $1}')
    total_bytes=$(( total_bytes + sz ))
    sz_h=$(/usr/bin/du -sh "$p" 2>/dev/null | /usr/bin/awk '{print $1}')
    printf "  %-58s %8s\n" "$(basename "$p")" "$sz_h"
  fi
done
echo ""
total_mb=$(( total_bytes / 1024 / 1024 ))
echo "Kandidaten-TOTAL: ${total_mb} MB (Sicher: regenerierbar)"
if casual_ask "Diese Personal-Caches loeschen?"; then
  for p in "${APPS[@]}"; do
    [ -e "$p" ] && /usr/bin/find "$p" -depth -delete 2>/dev/null
  done
fi

# ========================================================
# 5. Notification DB
# ========================================================
header "[5/8] Notification-DB ~/Library/UserNotifications/"
NOT_DIR="$H/Library/UserNotifications"
if [ -d "$NOT_DIR" ]; then
  sz=$(/usr/bin/du -sh "$NOT_DIR" 2>/dev/null | /usr/bin/awk '{print $1}')
  echo "Gesamtgroesse: $sz"
  if [ "$YES" = "1" ] || (read -p "  Wipe Notification DB? Hinweis: ungelesene In-App-Notifs weg. [y/N]: " ans; [ "$ans" = "y" ] || [ "$ans" = "Y" ]); then
    if [ "$YES" != "1" ]; then
      # we already asked via read combined; just verify
      : # placeholder
    fi
    /usr/bin/find "$NOT_DIR" -mindepth 1 -depth -delete 2>/dev/null && echo "  [OK] Notifications DB gecleart."
  else
    echo "  [skip]"
  fi
fi

# ========================================================
# 6. Font Cache
# ========================================================
header "[6/8] Font-Cache (rebuild on next app launch)"
FONTS_USR=$(/usr/bin/du -sh "$H/Library/Fonts/" 2>/dev/null | /usr/bin/awk '{print $1}')
echo "~/Library/Fonts: $FONTS_USR"
echo "Hinweis: Cache rebuild dauert 5-30 Sek."
if casual_ask "Font-Cache-Reset (atsutil databases -removeUser + cfprefsd restart)?"; then
  /usr/bin/atsutil databases -removeUser 2>/dev/null || true
  /usr/bin/atsutil databases -remove 2>/dev/null || true
  /usr/bin/killall cfprefsd 2>/dev/null || true
  echo "  [OK] Font-Cache reset (rebuild im Hintergrund)."
 fi

# ========================================================
# 7. QuickLook Cache
# ========================================================
header "[7/8] QuickLook-Cache"
QL_DIR="$H/Library/Caches/com.apple.QuickLook"
if [ -d "$QL_DIR" ]; then
  sz=$(/usr/bin/du -sh "$QL_DIR" 2>/dev/null | /usr/bin/awk '{print $1}')
  echo "Groesse: $sz"
  if casual_ask "QuickLook-Cache loeschen?"; then
    /usr/bin/find "$QL_DIR" -depth -delete 2>/dev/null
  fi
fi

# ========================================================
# 8. Hidden-Apple-Subsystems sudo-Befehle (§15)
# ========================================================
header "[8/8] sudo-Befehle fuer §15 Hidden-Subsystems (User kopiert)"
cat <<'EOF'
# Coreduetd (Handoff, Apple-Watch Auto-Unlock)
sudo launchctl disable system/com.apple.coreduetd

# sharingd (AirDrop/SMB/Screen-Share)
sudo launchctl disable system/com.apple.sharingd

# usbmuxd (iPhone-Sync via USB) — NUR wenn du kein iPhone-USB-Backup brauchst!
sudo launchctl disable system/com.apple.usbmuxd

# cupsd (Printing — NUR wenn kein Drucker!)
sudo launchctl disable system/com.apple.cupsd

# searchpartyd (Mac-zu-Mac Bonjour)
sudo launchctl disable system/com.apple.searchpartyd

# applepushserviced (Push-Notifications — nur wenn du kein iMessage/Push willst)
sudo launchctl disable system/com.apple.applepushserviced

# symptomsd (Network-Diagnostic → Apple)
sudo launchctl disable system/com.apple.symptomsd

# feedbacklogger (Feedback-Datensammler)
sudo launchctl disable system/com.apple.feedbacklogger

# accessoryupdaterd (AirPods/Watch Firmware)
sudo launchctl disable system/com.apple.accessoryupdaterd

# ondeviceassistantd (Siri on-device)
sudo launchctl disable system/com.apple.ondeviceassistantd

# amsaccountsd (Apple-Music-Accountancy RAM-Kleptomane)
sudo launchctl disable system/com.apple.amsaccountsd
EOF

# ========================================================
# Validation
# ========================================================
header "VALIDATION"
/bin/df -h /System/Volumes/Data | /usr/bin/tail -1
/usr/bin/top -l 1 -n 1 | /usr/bin/head -5
/bin/launchctl list 2>/dev/null | /usr/bin/wc -l | /usr/bin/awk '{printf "Remaining launchd-Jobs: %s\n", $1}'

printf "\n=== DONE — sudo-Befehle oben kopieren + Mac-PW eingeben ===\n"
