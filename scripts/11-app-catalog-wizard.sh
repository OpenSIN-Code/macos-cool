#!/usr/bin/env bash
# 11-app-catalog-wizard.sh — vollständiger App-Inventar (/Applications)
#
# Erzeugt eine Markdown-Tabelle aller GUI-Apps mit:
#  - Bundle Name + ID + Version
#  - Install-Size
#  - Verknüpfte Application Support / Cache / Prefs / Launchagent / Sandbox-Container
#  - Risiko-Stufe + Suggested-Action
#
# Usage: bash scripts/11-app-catalog-wizard.sh [--json] [--full] [--std alone]
#   --json   JSON-Output für Programmierung
#   --full   jede Pfad-Information (kann lang sein)

set -uo pipefail

H="$HOME"
MODE="table"
[ "${1:-}" = "--json" ] && MODE="json"

# ------------------------------------------------------------------------
# Bekannte Bloat-Providernamen (cross-ref)
# ------------------------------------------------------------------------
BLOAT_PROVIDERS=(
  "TotalAV"
  "Avast"
  "AVG"
  "Norton"
  "Bitdefender"
  "McAfee"
  "Mcafee"
  "Sophos"
  "WebCatalog"
  "Wondershare"
  "Filmora"
  "AniEraser"
  "iproyal"
  "Pawns"
  "Grass"
  "getgrass"
  "Caracal"
  "Honeyminer"
  "Cudo"
  "NiceHash"
  "Salad"
  "Adobe"  # wenn Adobe Acrobat Pro / Photoshop etc., kein Photoshop-Pro für Devs
  "JetBrains"  # Toolbox → wenn keine IDE mehr, kann weg
  "MEGA"
  "Stronghold"  # Heavy Electron-Game-Cache
  "Genymotion"  # Android-Emulator
  "Nox"  # NoxPlayer-Emulator
  "Parallels"  # VM-Manager
  "UnrealEditor"
  "AniEraser"
  "FilmoraGo"
  "Anker"
  "TotalAV"
  "MyCleanMac"
  "MacBooster"
  "CleanMyMac"
)

is_known_bloat() {
  local n="$(echo "$1" | /usr/bin/tr '[:upper:]' '[:lower:]')"
  for kw in "${BLOAT_PROVIDERS[@]}"; do
    local lckw="$(echo "$kw" | /usr/bin/tr '[:upper:]' '[:lower:]')"
    [[ "$n" == *"$lckw"* ]] && return 0
  done
  return 1
}

# ------------------------------------------------------------------------
# Per-App-Metadaten
# ------------------------------------------------------------------------
scan_app() {
  local app_path="$1"
  local info="$app_path/Contents/Info.plist"
  [ -f "$info" ] || return

  local name="$(basename "$app_path" .app)"
  local bundle_id="$(/usr/bin/defaults read "$app_path/Contents/Info" CFBundleIdentifier 2>/dev/null || echo "?")"
  local version="$(/usr/bin/defaults read "$app_path/Contents/Info" CFBundleShortVersionString 2>/dev/null || echo "?")"
  local size="$(/usr/bin/du -sh "$app_path" 2>/dev/null | /usr/bin/awk '{print $1}')"
  [ -z "$size" ] && size="-"

  # Sandbox-Container (wenn vorhanden)
  local container=""
  if [[ "$bundle_id" == com.apple.* ]]; then
    container="-"
  else
    # Bif einer Container-Pfad
    [ -d "$H/Library/Containers/$(basename "$bundle_id")" ] && container="$H/Library/Containers/$(basename "$bundle_id")"
    or_id="$(echo "$bundle_id" | /usr/bin/awk -F. '{print $(NF-1)"."$NF}')"
    [ -z "$container" ] && [ -d "$H/Library/Containers/${or_id}" ] && container="$H/Library/Containers/${or_id}"
    [ -z "$container" ] && container="-"
  fi

  # Application Support (kompletter Stack)
  local support=""
  for q in \
    "$H/Library/Application Support/${name}" \
    "$H/Library/Application Support/${bundle_id}" \
    "$H/Library/Application Support/${bundle_id%.*}.*"; do
    [ -d "$q" ] && support="$q"
  done
  [ -z "$support" ] && support="-"

  # Caches
  local cache=""
  for q in \
    "$H/Library/Caches/${name}" \
    "$H/Library/Caches/${bundle_id}"; do
    [ -d "$q" ] && cache="$q"
  done
  [ -z "$cache" ] && cache="-"

  # LaunchAgent (falls vorhanden)
  local la=""
  for q in \
    "$H/Library/LaunchAgents/${bundle_id}.plist" \
    "$H/Library/LaunchAgents/${name}.plist"; do
    [ -f "$q" ] && la="$q"
  done
  [ -z "$la" ] && la="-"

  # System-Level (root-owned) – nur Existenz, nicht löschen
  local sysla=""
  for q in \
    "/Library/LaunchAgents/${bundle_id}.plist" \
    "/Library/LaunchDaemons/${bundle_id}.plist"; do
    [ -f "$q" ] && sysla="$q"
  done
  [ -z "$sysla" ] && sysla="-"

  # Risiko-Klasse bestimmen
  local risk="unknown"
  if is_known_bloat "$name"; then
    risk="KNOWN-BLOAT"
  elif [[ "$bundle_id" == com.google.Chrome || "$bundle_id" == com.brave.Browser \
        || "$name" == "Google Chrome" || "$name" == "Google Chrome Stable" \
        || "$name" == "Brave Browser" || "$name" == "Firefox" \
        || "$name" == "Safari" || "$name" == "Microsoft Edge" \
        || "$name" == "Arc" || "$name" == "Opera" ]]; then
    risk="BROWSER"  # Browser selbst behalten, Caches/Profile-State sind separat (siehe §5)
  elif [[ "$bundle_id" == com.apple.* ]]; then
    if [[ "$name" == "Safari" || "$name" == "Mail" || "$name" == "Photos" \
          || "$name" == "Notes" || "$name" == "Reminders" \
          || "$name" == "Calendar" || "$name" == "Stickies" \
          || "$name" == "Preview" || "$name" == "TextEdit" ]]; then
      risk="APPLE-STOCK"
    else
      risk="APPLE-SYSTEM"
    fi
  elif [[ "$name" == "Docker" ]] || [[ "$name" == "Ollama" ]]; then
    risk="DEV-RUNTIME"
  elif [[ "$name" == "Xcode" ]] || [[ "$name" == "AndroidStudio"* ]] \
        || [[ "$name" == "Kiro"* ]] || [[ "$name" == "iTerm"* ]] \
        || [[ "$name" == "Warp"* ]] || [[ "$name" == "Python"* ]]; then
    risk="DEV-TOOL"
  elif [[ "$name" == "Hidden Bar" || "$name" == "MenubarX" || "$name" == "Disk Drill" \
        || "$name" == "Dropover" || "$name" == "Speedtest" \
        || "$name" == "hide.me" || "$name" == "TeraBox" ]]; then
    risk="UTILITY"  # Ask User
  elif [[ "$name" == "Craft" || "$name" == "WhatsApp" || "$name" == "Notion" \
        || "$name" == "Slack" || "$name" == "Discord" \
        || "$name" == "Spotify" || "$name" == "Whatsapp" \
        || "$name" == "Stronghold"* ]]; then
    risk="PRODUCTIVE"
  else
    risk="UNKNOWN-APP"  # User-Attention
  fi

  # Suggested Action
  local action="-"
  case "$risk" in
    KNOWN-BLOAT)   action="COMPLETELY: rm-rf .app + Support + Cache + Prefs + LaunchAgent" ;;
    BROWSER)       action="KEEP .app; §5 für Cache (Logins behalten!)" ;;
    APPLE-STOCK)   action="KEEP - OS uses it" ;;
    APPLE-SYSTEM)  action="KEEP - OS system" ;;
    DEV-TOOL)      action="KEEP; Caches/Support putzen OK" ;;
    DEV-RUNTIME)  action="KEEP; Container/VM-Daten NICHT ohne Confirm" ;;
    UTILITY)       action="ASK User - pro App" ;;
    PRODUCTIVE)    action="ASK User - private Daten enthalten" ;;
    UNKNOWN-APP)   action="ASK User - was ist das?" ;;
    *)             action="ASK User" ;;
  esac

  printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n" \
    "$name" "$bundle_id" "$version" "$size" "$risk" "$action" "$support" "$cache" "$container" "$la"
}

# ------------------------------------------------------------------------
# Lauf
# ------------------------------------------------------------------------
print_table_header() {
  printf "%-32s  %-36s  %-9s  %-7s  %-13s\n" \
    "APP" "BUNDLE-ID" "VERSION" "SIZE" "RISK"
  printf "%-32s  %-36s  %-9s  %-7s  %-13s\n" \
    "$(printf '%.0s-' {1..32})" "$(printf '%.0s-' {1..36})" "$(printf '%.0s-' {1..9})" "$(printf '%.0s-' {1..7})" "$(printf '%.0s-' {1..13})"
}

if [ "$MODE" = "json" ]; then
  echo "["
  first=1
  for app in /Applications/*.app /Applications/Utilities/*.app; do
    [ -d "$app" ] || continue
    info="$app/Contents/Info.plist"
    [ -f "$info" ] || continue
    name="$(basename "$app" .app)"
    bundle_id="$(/usr/bin/defaults read "$app/Contents/Info" CFBundleIdentifier 2>/dev/null || echo "?")"
    version="$(/usr/bin/defaults read "$app/Contents/Info" CFBundleShortVersionString 2>/dev/null || echo "?")"
    size="$(/usr/bin/du -sh "$app" 2>/dev/null | /usr/bin/awk '{print $1}')"
    is_known="false"
    is_known_bloat "$name" && is_known="true"

    [ "$first" = "0" ] && echo ","
    printf "  {\"name\":\"%s\",\"bundle\":\"%s\",\"version\":\"%s\",\"size\":\"%s\",\"bloat_known\":%s}" \
      "$name" "$bundle_id" "$version" "$size" "$is_known"
    first=0
  done
  echo ""
  echo "]"
else
  printf "============================================================\n"
  printf "  macos-cool · APP-CATALOG · /Applications + Utilities/\n"
  printf "============================================================\n\n"

  sep() { printf "%s\n" "--------------------------------------------------------------------"; }

  # Risiko-Gruppierung
  for klass in "KNOWN-BLOAT" "DEV-RUNTIME" "BROWSER" "DEV-TOOL" "PRODUCTIVE" "UTILITY" "APPLE-SYSTEM" "APPLE-STOCK" "UNKNOWN-APP"; do
    found=0
    for app in /Applications/*.app /Applications/Utilities/*.app; do
      [ -d "$app" ] || continue
      info="$app/Contents/Info.plist"
      [ -f "$info" ] || continue
      name="$(basename "$app" .app)"
      bundle_id="$(/usr/bin/defaults read "$app/Contents/Info" CFBundleIdentifier 2>/dev/null || echo "?")"
      [ "$bundle_id" = "$name" ] && bundle_id="?"
      version="$(/usr/bin/defaults read "$app/Contents/Info" CFBundleShortVersionString 2>/dev/null || echo "?")"
      size="$(/usr/bin/du -sh "$app" 2>/dev/null | /usr/bin/awk '{print $1}')"
      [ -z "$size" ] && size="-"

      risk="UNKNOWN-APP"
      if is_known_bloat "$name"; then
        risk="KNOWN-BLOAT"
      elif [[ "$bundle_id" == com.google.Chrome || "$bundle_id" == com.brave.Browser \
            || "$name" == "Google Chrome" || "$name" == "Google Chrome Stable" \
            || "$name" == "Brave Browser" || "$name" == "Firefox" \
            || "$name" == "Microsoft Edge" \
            || "$name" == "Arc" || "$name" == "Opera" ]]; then
        risk="BROWSER"
      elif [[ "$bundle_id" == com.apple.* ]]; then
        if [[ "$name" == "Safari" || "$name" == "Mail" || "$name" == "Photos" \
              || "$name" == "Notes" || "$name" == "Reminders" \
              || "$name" == "Calendar" || "$name" == "Stickies" \
              || "$name" == "Preview" || "$name" == "TextEdit" ]]; then
          risk="APPLE-STOCK"
        else
          risk="APPLE-SYSTEM"
        fi
      elif [[ "$name" == "Docker" ]] || [[ "$name" == "Ollama" ]]; then
        risk="DEV-RUNTIME"
      elif [[ "$name" == "Xcode" ]] || [[ "$name" == "AndroidStudio"* ]] \
            || [[ "$name" == "Kiro"* ]] || [[ "$name" == "iTerm"* ]] \
            || [[ "$name" == "Warp"* ]] || [[ "$name" == "Python"* ]]; then
        risk="DEV-TOOL"
      elif [[ "$name" == "Hidden Bar" || "$name" == "MenubarX" || "$name" == "Disk Drill" \
            || "$name" == "Dropover" || "$name" == "Speedtest" \
            || "$name" == "hide.me" || "$name" == "TeraBox" ]]; then
        risk="UTILITY"
      elif [[ "$name" == "Craft" || "$name" == "WhatsApp" || "$name" == "Notion" \
            || "$name" == "Slack" || "$name" == "Discord" \
            || "$name" == "Spotify" \
            || "$name" == "Stronghold"* ]]; then
        risk="PRODUCTIVE"
      fi

      if [ "$risk" = "$klass" ]; then
        if [ "$found" = "0" ]; then
          echo ""
          sep
          echo "  $klass"
          sep
          printf "  %-32s  %-36s  %-9s  %-7s\n" "APP" "BUNDLE-ID" "VERSION" "SIZE"
          sep
          found=1
        fi
        printf "  %-32s  %-36s  %-9s  %-7s\n" \
          "$(echo "$name" | /usr/bin/cut -c1-32)" "$(echo "$bundle_id" | /usr/bin/cut -c1-36)" "$version" "$size"
      fi
    done
    [ "$found" = "1" ] && sep
  done

  echo ""
  echo "============================================================"
  echo "  Suggested Actions"
  echo "============================================================"
  cat <<'ACTIONS'
KNOWN-BLOAT: rm -rf /Applications/<App>.app + alle Support/Cache/Prefs/LaunchAgent
BROWSER    : KEEP .app; siehe §5 (Caches OK, Logins NICHT)
DEV-RUNTIME: KEEP; Container kann User-Daten enthalten
DEV-TOOL   : KEEP; Caches putzen OK
PRODUCTIVE : ASK User - private Daten evtl
UTILITY    : ASK User - pro App
APPLE-STOCK: KEEP - OS-uses
APPLE-SYSTEM: KEEP - OS-system
UNKNOWN-APP: ASK User - was ist das?
ACTIONS

  echo ""
  echo "-----------------------------------"
  echo "  Wie weiter?"
  echo "-----------------------------------"
  cat <<'NEXT'
1. Schau die Tabelle oben an.
2. Sag jetzt dem Skill-Steller welche Bloat-Apps du Komplett putzen willst:
   - "loesche TeraBox komplett" → rm-rf App + Support + Caches + Container
   - "loesche Stronghold Kingdoms komplett" → falls nicht genutzt
   - "remove Microsoft ... komplett"
3. Pro App: agent erstellt individuelles Loesch-Skript mit Preview-Diff.
   Erst NACH deinem OK fuehrt er es aus.
NEXT
fi
