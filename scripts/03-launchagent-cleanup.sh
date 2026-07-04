#!/usr/bin/env bash
# 03-launchagent-cleanup.sh — User-LaunchAgents nach Provider-Liste.
# Interactive: bestaetigt pro Agent. Sudo-Befehle werden separat gePRINTet.
# Usage: bash scripts/03-launchagent-cleanup.sh [--auto] [--yes]

set -euo pipefail

H="$HOME"
AUTO=0
YES=0
[ "${1:-}" = "--auto" ] && AUTO=1
[ "${2:-}" = "--yes" ] && YES=1
[ "${1:-}" = "--yes" ] && YES=1

# Format: ID|Pfad|Kommentar
declare -a AGENTS=(
  "adobe-arm-helper|$H/Library/LaunchAgents/com.adobe.ARMDCHelper.*.plist|Adobe ARM Background-Update"
  "adobe-dunamis|$H/Library/Application Support/com.adobe.dunamis|Adobe Drosseln/Cloud Cache (70 MB)"
  "adobe-app-support|$H/Library/Application Support/Adobe|Adobe Application Support (31 MB)"
  "adobe-caches|$H/Library/Caches/Adobe|Adobe Caches"
  "adobe-prefs-ordner|$H/Library/Preferences/Adobe|Adobe Preferences Folder"
  "adobe-prefs-list|$H/Library/Preferences/com.adobe.*.plist|Adobe Preferences Files"
  "jetbrains-toolbox|$H/Library/LaunchAgents/com.jetbrains.toolbox.plist|JetBrains Toolbox Updater"
  "jetbrains-app-support|$H/Library/Application Support/JetBrains|JetBrains IDE-State"
  "jetbrains-space|$H/Library/Application Support/JetBrains Space|JetBrains Space Cloud"
  "jetbrains-prefs|$H/Library/Preferences/com.jetbrains.*.plist|JetBrains Preferences"
  "jetbrains-ps-prefs|$H/Library/Preferences/jetbrains.ps.*.plist|JetBrains Ps Prefs"
  "epic-launcher|$H/Library/LaunchAgents/com.epicgames.launcher.plist|Epic Games Launcher"
  "epic-prefs|$H/Library/Preferences/com.epicgames.*.plist|Epic Games Preferences"
  "mega-updater|$H/Library/LaunchAgents/mega.mac.megaupdater.plist|MEGA Cloud Update Helper"
  "mega-app-support|$H/Library/Application Support/Mega Limited|MEGA App Data (22 MB)"
  "grass-launcher|$H/Library/LaunchAgents/Grass.plist|Grass Crypto Bandwidth (P2P Earning)"
  "grass-app-support|$H/Library/Application Support/ip_royal_paws|Grass IP-Royal Paws"
  "grass-prefs|$H/Library/Preferences/io.getgrass.desktop.plist|Grass Desktop Preferences"
  "notebooklm|$H/Library/LaunchAgents/com.aiometrics.notebooklm.daily.plist|NotebookLM Daily"
  "aws-codewhisperer|$H/Library/LaunchAgents/com.amazon.codewhisperer.launcher.plist|AWS CodeWhisperer"
  "totalav-app-support|$H/Library/Application Support/net.protected.macos.TotalAV|TotalAV Cache (481 MB)"
  "totalav-prefs|$H/Library/Preferences/net.protected.macos.TotalAV.plist|TotalAV Preferences"
  "google-keystone|$H/Library/LaunchAgents/com.google.keystone.agent.plist|Google Chrome Updater"
  "google-keystone-xpc|$H/Library/LaunchAgents/com.google.keystone.xpcservice.plist|Google Chrome Updater XPC"
  "google-updater-wake|$H/Library/LaunchAgents/com.google.GoogleUpdater.wake.plist|Google Updater Wake"
  "google-updater-cache|$H/Library/Application Support/Google/GoogleUpdater|Google Update Cache (700 MB)"
  "google-drive-cache|$H/Library/Caches/com.google.GoogleDriveFS|Google DriveFS Cache"
  "homebrew-mysql|$H/Library/LaunchAgents/homebrew.mxcl.mysql.plist|Homebrew MySQL Service"
  "homebrew-postgres15|$H/Library/LaunchAgents/homebrew.mxcl.postgresql@15.plist|Homebrew Postgres 15"
  "homebrew-postgres16|$H/Library/LaunchAgents/homebrew.mxcl.postgresql@16.plist|Homebrew Postgres 16"
  "homebrew-redis|$H/Library/LaunchAgents/homebrew.mxcl.redis.plist|Homebrew Redis"
)

# Sudo-Sektion (Agent PRINT-only):
SUDO_COMMANDS=(
  "sudo rm -f /Library/LaunchAgents/com.adobe.ARMDCHelper.*.plist"
  "sudo rm -f /Library/LaunchDaemons/com.adobe.ARMDC.Communicator.plist"
  "sudo rm -f /Library/LaunchDaemons/com.adobe.ARMDC.SMJobBlessHelper.plist"
  "sudo rm -f /Library/LaunchDaemons/net.protected.macos.AVHelper.plist"
)

echo "=== macos-cool · launchagent-cleanup ==="
echo ""
printf "%-5s %-25s %-15s %s\n" "#" "ID" "GROESSE" "BESCHREIBUNG"
echo "----------------------------------------------------------------------"

i=0
declare -a TODOS
for agent in "${AGENTS[@]}"; do
  IFS='|' read -r id path desc <<< "$agent"
  i=$(( i + 1 ))
  sz=$(/usr/bin/du -sh "$path" 2>/dev/null | /usr/bin/awk '{print $1}')
  printf "[%2d] %-25s %-15s %s\n" "$i" "$id" "${sz:-n/a}" "$desc"
  TODOS+=("$agent")
done

echo ""
echo "--- SUDO-Befehle (nicht ausgefuehrt durch Skript; User kopiert) ---"
for cmd in "${SUDO_COMMANDS[@]}"; do
  printf "  %s\n" "$cmd"
done
echo ""

if [ "$AUTO" = "1" ]; then
  if [ "$YES" != "1" ]; then
    echo "Auto erfordert --yes. Abbruch."
    exit 1
  fi
fi

for idx in "${!TODOS[@]}"; do
  IFS='|' read -r id path desc <<< "${TODOS[$idx]}"
  if [ "$AUTO" = "1" ] || [ "$YES" = "1" ]; then
    ans="yes"
  else
    printf "[%2d/%2d] %s (%s) loeschen ? [%s] [y/N/skip-rest/keep-all]: " \
      "$((idx+1))" "${#TODOS[@]}" "$id" "${desc:0:60}" ""
    read -r ans
    case "$ans" in
      y|Y|yes|Yes) ans="yes" ;;
      all|a) ans="yes"; AUTO=1; YES=1 ;;
      *) ans="no" ;;
    esac
    if [ "$ans" = "skip-rest" ]; then echo "Rest uebersprungen."; break; fi
    if [ "$ans" = "keep-all" ]; then echo "Stop."; exit 0; fi
  fi
  if [ "$ans" = "yes" ]; then
    if [ -e "$path" ]; then
      if [ -d "$path" ]; then
        /usr/bin/find "$path" -depth -delete 2>/dev/null && echo "  [OK] dir:    $path"
      else
        /bin/rm -f "$path" 2>/dev/null && echo "  [OK] file:   $path"
      fi
    else
      echo "  [skip] nicht da: $path"
    fi
  else
    echo "  [skip] user said no: $id"
  fi
done

echo ""
echo "Fertig. Sudo-Befehle oben manuell ausfuehren falls gewuenscht."
echo "Pruefe Ergebnis mit:"
echo "  ls -la $H/Library/LaunchAgents"
echo "  du -sh $H/Library/Application\ Support/Adobe"
