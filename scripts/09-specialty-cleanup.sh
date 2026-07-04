#!/usr/bin/env bash
# 09-specialty-cleanup.sh — §24 Specialty-Bloat-Pfade.
# Usage: bash scripts/09-specialty-cleanup.sh [profile] [--auto|--yes]

set -euo pipefail

PROFILE="${1:-developer}"
YES=0
for a in "$@"; do
  case "$a" in
    --auto|--yes) YES=1 ;;
    --profile=*) PROFILE="${a#--profile=}" ;;
  esac
done

H="$HOME"

header() { printf "\n=== %s ===\n" "$1"; }
ask() {
  if [ "$YES" = "1" ]; then return 0; fi
  printf "  %s [y/N]: " "$1"
  read -r ans
  case "$ans" in
    y|Y|yes|Yes) return 0 ;;
    *) return 1 ;;
  esac
}

header "macos-cool · 09-specialty-cleanup · profile=$PROFILE"

# ============================================
# 24.1 Quick Look + OCR Caches
# ============================================
header "[1/6] Quick-Look + OCR Caches (§24.1)"
QL_DIR="$H/Library/Caches"
declare -a QL_PATHS=(
  "$QL_DIR/com.apple.QuickLook.thumbnailcache"
  "$QL_DIR/com.apple.quicklook.ui.helper"
  "$QL_DIR/com.apple.QuickLook"
)
total_bytes=0
for p in "${QL_PATHS[@]}"; do
  if [ -d "$p" ]; then
    sz=$(/usr/bin/du -sh "$p" 2>/dev/null | /usr/bin/awk '{print $1}')
    b=$(/usr/bin/du -sb "$p" 2>/dev/null | /usr/bin/awk '{print $1}')
    printf "  %-58s %8s\n" "$p" "$sz"
    total_bytes=$(( total_bytes + b ))
  fi
done
echo ""
echo "/var/folders User-PER-Var Quick-Look:"
/usr/bin/find /var/folders/"$USER" -type d -name "com.apple.QuickLook*" 2>/dev/null | /usr/bin/head -5 | while read -r p; do
  sz=$(/usr/bin/du -sh "$p" 2>/dev/null | /usr/bin/awk '{print $1}')
  printf "  %-58s %8s\n" "$p" "$sz"
done
total_mb=$(( total_bytes / 1024 / 1024 ))
printf "\nQuick-Look Caches TOTAL: %s MB\n" "$total_mb"

if ask "Quick-Look-Caches + qlmanage -r reinit?"; then
  for p in "${QL_PATHS[@]}"; do
    [ -d "$p" ] && /usr/bin/find "$p" -depth -delete 2>/dev/null && echo "  [$OK] $p gelöscht"
  done
  /usr/bin/find /var/folders/"$USER" -type d -name "com.apple.QuickLook*" -exec /usr/bin/find {} -depth -delete \; 2>/dev/null || true
  /usr/bin/qlmanage -r 2>/dev/null && echo "  [$OK] qlmanage -r (rebuild next preview)"
fi

# ============================================
# 24.2 AirPort Legacy Updater (sudo)
# ============================================
header "[2/6] AirPort Legacy Updater (§24.2, sudo nötig)"
printf "Diese Datei ist meist toter Code seit Sierra:\n"
printf "  /Library/LaunchAgents/com.apple.AirPortPrefsUpdater.plist\n"
if [ -e /Library/LaunchAgents/com.apple.AirPortPrefsUpdater.plist ]; then
  /bin/ls -la /Library/LaunchAgents/com.apple.AirPortPrefsUpdater.plist 2>&1
  echo ""
  if ask "sudo rm dieser Datei?"; then
    printf "  Copy-Paste: sudo rm -f /Library/LaunchAgents/com.apple.AirPortPrefsUpdater.plist\n"
    /usr/bin/sudo -n /bin/rm -f /Library/LaunchAgents/com.apple.AirPortPrefsUpdater.plist 2>&1 && echo "  [OK] direkt" || echo "  [manual] sudo PW-Eingabe noetig"
  fi
else
  echo "  [OK nicht da] Datei existiert nicht."
fi

# ============================================
# 24.3 Mail-Plugin-Caches
# ============================================
header "[3/6] Mail-Plugin-Caches (§24.3)"
MAIL_CACHE="$H/Library/Containers/com.apple.mail/Data/Library/Caches/Library/Application Support/com.apple.Mail/Library/Caches/com.apple.Mail.LSPlugins"
if [ -d "$MAIL_CACHE" ]; then
  sz=$(/usr/bin/du -sh "$MAIL_CACHE" 2>/dev/null | /usr/bin/awk '{print $1}')
  printf "  Groesse: %s\n" "$sz"
  printf "  Path:    %s\n" "$MAIL_CACHE"
  if ask "Mail-Plugin-Cache loeschen?"; then
    /usr/bin/find "$MAIL_CACHE" -depth -delete 2>/dev/null && echo "  [$OK]"
  fi
else
  echo "  [skip] nicht da."
fi

# Thunderbolt + Mail-Plugins (etc)
echo ""
echo "(Mail-Account-DB und Mail-Inhalt werden NICHT angefasst — bleiben unter"
echo " ~/Library/Mail/V*/MailData/ und ~/Library/Containers/com.apple.mail/Data/Library/Mail/)"

# ============================================
# 24.4 Thunderbolt/eGPU Daemon (sudo)
# ============================================
header "[4/6] Thunderbolt/eGPU Daemon (§24.4, sudo nötig)"
printf "Frage dich: hast du eine echte eGPU oder vollwertiges Thunderbolt-Dock?\n"
printf "  - Wenn NEIN (nur USB-Sticks/Displays): kann disablemn werden.\n"
printf "  - Wenn JA: BEHALTEN.\n"
if ask "sudo launchctl disable com.apple.thunderboltSettings?"; then
  /usr/bin/sudo -n /usr/bin/launchctl disable system/com.apple.thunderboltSettings 2>&1 && echo "  [OK]" \
    || echo "  [manual] kopiere: sudo launchctl disable system/com.apple.thunderboltSettings"
fi

# ============================================
# 24.5 FCP Workflow Caches
# ============================================
header "[5/6] Final Cut Pro Cache (§24.5)"
FCP_CACHE="$H/Movies/Final Cut Pro.fcpbundle/Library/Caches/"
FCP_APP_CACHE="$H/Library/Application Support/com.apple.FinalCutPro/Library/Caches/"
for p in "$FCP_CACHE" "$FCP_APP_CACHE"; do
  if [ -d "$p" ]; then
    sz=$(/usr/bin/du -sh "$p" 2>/dev/null | /usr/bin/awk '{print $1}')
    printf "  %-58s %8s\n" "$p" "$sz"
  fi
done
echo ""
echo "(FCP Library / CurrentVersion.fcpevent / Original Media werden NICHT angefasst)"
if ask "FCP cache loeschen?"; then
  for p in "$FCP_CACHE" "$FCP_APP_CACHE"; do
    [ -d "$p" ] && /usr/bin/find "$p" -depth -delete 2>/dev/null && echo "  [$OK] $p"
  done
fi

# ============================================
# 24.6 Minecraft Realm/Mod Cache
# ============================================
header "[6/6] Minecraft Webcache (§24.6)"
declare -a MC_PATHS=(
  "$H/Library/Application Support/minecraft/webcache"
  "$H/Library/Caches/mojang-launcher"
  "$H/Library/LaunchAgents/com.apple.Minecraft"*
)
total_bytes=0
for p in "${MC_PATHS[@]}"; do
  if [ -d "$p" ]; then
    sz=$(/usr/bin/du -sh "$p" 2>/dev/null | /usr/bin/awk '{print $1}')
    b=$(/usr/bin/du -sb "$p" 2>/dev/null | /usr/bin/awk '{print $1}')
    printf "  %-58s %8s\n" "$p" "$sz"
    total_bytes=$(( total_bytes + b ))
  fi
done
total_mb=$(( total_bytes / 1024 / 1024 ))
echo ""
echo "Minecraft-Cache-TOTAL: $total_mb MB (Welten/saves NICHT angefasst)"
if ask "Minecraft Webcache + Launcher-Cache loeschen?"; then
  for p in "${MC_PATHS[@]}"; do
    [ -d "$p" ] && /usr/bin/find "$p" -depth -delete 2>/dev/null && echo "  [$OK] $p"
  done
fi

# ============================================
# Validation
# ============================================
header "VALIDATION"
/bin/df -h /System/Volumes/Data | /usr/bin/tail -1
echo ""
printf "Done. sudo-Befehle (ggfs. manuell):\n"
cat <<'EOF'
  sudo rm -f /Library/LaunchAgents/com.apple.AirPortPrefsUpdater.plist
  sudo launchctl disable system/com.apple.thunderboltSettings
EOF
