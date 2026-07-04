#!/usr/bin/env bash
# 01-inventory.sh — read-only scan of macOS bloat candidates.
# Safe: keine Schreibzugriffe, nur du + ls + ps.
# Usage: bash scripts/01-inventory.sh [--profile developer-minimal|developer|power-user|privacy-paranoid]

set -euo pipefail

PROFILE="${1:-developer}"

H="$HOME"

header() { printf "\n=== %s ===\n" "$1"; }
section() { printf "\n--- %s ---\n" "$1"; }

header "macos-cool · INVENTORY  · profile=$PROFILE"
printf "macOS:  %s\n" "$(/usr/bin/sw_vers -productVersion)"
printf "Build:  %s\n" "$(/usr/bin/sw_vers -buildVersion)"
printf "Kernel: %s\n" "$(/usr/sbin/sysctl -n kern.version 2>/dev/null | /usr/bin/cut -d' ' -f1)"
printf "Cores:  %s\n" "$(/usr/sbin/sysctl -n hw.ncpu)"
printf "RAM:    %s GB\n" "$(/usr/sbin/sysctl -n hw.memsize | /usr/bin/awk '{print int($1/1024/1024/1024)}')"
printf "Disk:   "
/bin/df -h /System/Volumes/Data | /usr/bin/tail -1 | /usr/bin/awk '{print $4 " free of " $2 " (" $5 " used)"}'

header "A · Heavyweight Directories (Library)"
/usr/bin/du -sh "$H/Library/"* 2>/dev/null | /usr/bin/sort -h | /usr/bin/tail -10

header "B · Heavyweight Directories (Home)"
/usr/bin/du -sh "$H/"*/  2>/dev/null | /usr/bin/sort -h | /usr/bin/tail -10

header "C · ~/Library/Caches TOP 15"
/usr/bin/du -sh "$H/Library/Caches/"* 2>/dev/null | /usr/bin/sort -h | /usr/bin/tail -15

header "D · ~/Library/Application Support TOP 15"
/usr/bin/du -sh "$H/Library/Application Support/"* 2>/dev/null | /usr/bin/sort -h | /usr/bin/tail -15

header "E · ~/Library/LaunchAgents (User Auto-launch)"
/bin/ls -lt "$H/Library/LaunchAgents/" 2>/dev/null

header "F · /Library/LaunchAgents (System · root-owned)"
/bin/ls -lt "/Library/LaunchAgents/" 2>/dev/null | /usr/bin/head -25

header "G · /Library/LaunchDaemons (System · root-owned)"
/bin/ls -lt "/Library/LaunchDaemons/" 2>/dev/null | /usr/bin/wc -l
/bin/ls -lt "/Library/LaunchDaemons/" 2>/dev/null | /usr/bin/head -20

header "H · Running launchd jobs"
/bin/launchctl list 2>/dev/null | /usr/bin/wc -l
echo "(first 15 user-side:)"
/bin/launchctl list 2>/dev/null | /usr/bin/grep -E "^\-" | /usr/bin/head -15

header "I · Top RAM Consumers (Process Tree)"
/bin/ps aux 2>/dev/null | /usr/bin/sort -nrk 4 | /usr/bin/awk 'NR<=15 {printf "%-7s MEM: %s  CMD: %s\n", $2, $4, $11}'

header "J · Top CPU Consumers"
/usr/bin/top -l 1 -n 10 2>/dev/null | /usr/bin/awk 'NR>1 && $1 ~ /^[0-9]+$/ {printf "  PID=%-7s CPU=%s%% CMD=%s\n", $1, $3, $12}'

header "K · Spotlight + Photoanalyse Daemons"
echo "Active mdworker / mdworker_shared / photoanalysisd:"
/bin/ps axc -o pid,comm 2>/dev/null | /usr/bin/grep -E "mdworker|photoanalysisd|mdbulkimport|mds_stores" | /usr/bin/head -10

header "L · Time Machine Status"
/bin/launchctl list 2>/dev/null | /usr/bin/grep -iE "backupd|timemachine" | /usr/bin/head -5
/usr/bin/tmutil status 2>/dev/null | /usr/bin/head -5 || echo "tmutil not available"

header "M · APFS Local Snapshots"
/usr/bin/tmutil listlocalsnapshots / 2>/dev/null || echo "(none or tmutil disabled)"

header "N · Browser Profiles (Chrome)"
/bin/ls "$H/Library/Application Support/Google/Chrome/" 2>/dev/null | /usr/bin/grep -E "^(Default|Profile)" | /usr/bin/wc -l
/bin/ls "$H/Library/Application Support/Google/Chrome/" 2>/dev/null | /usr/bin/grep -E "^(Default|Profile)" | /usr/bin/head -10

header "O · Trash contents (sample)"
/bin/ls -la "$H/.Trash/" 2>/dev/null | /usr/bin/head -10
/usr/bin/find "$H/.Trash/" -type f 2>/dev/null | /usr/bin/wc -l | /usr/bin/awk '{printf "  %s files in Trash\n", $1}'

printf "\n=== Profile-spezifische Empfehlung ===\n"
case "$PROFILE" in
  developer-minimal)
    echo " → Empfohlen: ALLES außer Browser & 1 Editor. Keine Photos, keine Notizen, kein Mail-Client." ;;
  developer)
    echo " → Empfohlen: Apple-Bloat + Update-Agenten + Dev-Caches weg. Browser behalten." ;;
  power-user)
    echo " → Empfohlen: offensichtlichen Müll weg, Services falls nicht genutzt." ;;
  privacy-paranoid)
    echo " → Empfohlen: alles + Telemetrie/Sync/Siri aus." ;;
  *)
    echo " → Profil unbekannt. Standard = $PROFILE" ;;
esac

printf "\nInventur beendet.\n"
