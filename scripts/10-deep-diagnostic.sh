#!/usr/bin/env bash
# 10-deep-diagnostic.sh — SYSTEM-WEITES DEEP-AUDIT (read-only, no destructive ops).
#
# Deckt: Disk/Memory/CPU/IO/Power/Network/Privacy/Spotlight/Photoanalysis
#       APFS/Snapshots/Purgable-Space/Swap/Wired-Throttle/TCC-Full-Disk-Access
#       Bonjour/mDNS-Traffic/Kernel-Extensions/Orphan-Processes
#
# Usage: bash scripts/10-deep-diagnostic.sh [--short]
#   --short : einzeilig summary statt full report
#
# Output ist reines text — kann in einen Markdown-Report gepipet werden.

set -uo pipefail

H="$HOME"
SHORT=0
[ "${1:-}" = "--short" ] && SHORT=1

section() { printf "\n%s·%s·%s\n" "==============================" "  $1  " "=============================="; }
_kv() { printf "  %-30s %s\n" "$1" "$2"; }
_2k() { printf "  %-30s %-25s %s\n" "$1" "$2" "$3"; }

# =============================================================
# Header
# =============================================================
now=$(/bin/date "+%Y-%m-%d %H:%M:%S %Z")
echo ""
printf "============================================================\n"
printf "  macos-cool · DEEP-DIAGNOSTIC\n"
printf "  Generated:  %s\n" "$now"
printf "  Profile:    ${MACOS_PROFILE:-developer}\n"
printf "  Hostname:   %s\n" "$(/bin/hostname -s 2>/dev/null)"
printf "============================================================\n"

# =============================================================
#  [1] SYSTEM BASIS
# =============================================================
section "1 · SYSTEM BASIS"
_kv "macOS Version"          "$(/usr/bin/sw_vers -productVersion 2>/dev/null)"
_kv "Build / Arch"           "$(/usr/bin/sw_vers -buildVersion 2>/dev/null) / $(/usr/bin/uname -m 2>/dev/null)"
_kv "Kernel"                 "$(/usr/bin/uname -v 2>/dev/null)"
_kv "Hostname"               "$(/usr/bin/hostname 2>/dev/null)"
_kv "Uptime"                 "$(/usr/bin/uptime 2>/dev/null)"
_kv "Boot mode"              "$(/usr/sbin/ioreg -n IODeviceTree:/options | /usr/bin/grep -E 'boot-mode|secure-boot' 2>/dev/null | /usr/bin/head -1 || echo 'macOS')"
[ -f /System/Library/SystemVersion.plist ] && _kv "Sytem Volume sealed" "true (SSV)"
_kv "Cores / RAM"            "$(/usr/sbin/sysctl -n hw.ncpu 2>/dev/null) / $(( $(/usr/sbin/sysctl -n hw.memsize 2>/dev/null) / 1024 / 1024 / 1024 )) GB"
_kv "Model Identifier"       "$(/usr/sbin/sysctl -n hw.model 2>/dev/null)"

# =============================================================
#  [2] DISK / APFS / PURGABLE SPACE
# =============================================================
section "2 · DISK / APFS / PURGABLE"
printf "  [df / Data volume]\n"
/bin/df -h / 2>/dev/null | /usr/bin/awk 'NR==2 {printf "    Volume:     %s\n    Size:       %s used / %s total (%s full)\n    iused:      %s / %s\n", $1, $3, $2, $5, $6, $7}'
/bin/df -h /System/Volumes/Data 2>/dev/null | /usr/bin/tail -1 | /usr/bin/awk '{printf "    Data vol:   %s used / %s total (%s full)\n", $3, $2, $5}'

printf "\n  [APFS Volume Info]\n"
/usr/sbin/diskutil info / 2>/dev/null | /usr/bin/grep -E "Volume Name|Total Size|Volume Free Space|Purgeable Space|FileVault|Media Name|Protocol|Block Size" | /usr/bin/sed 's/^/    /'

printf "\n  [APFS Snapshots / TM]\n"
snap=$(/usr/bin/tmutil listlocalsnapshots / 2>/dev/null || echo "  (none)")
if [ -z "$snap" ] || [ "$snap" = "(none)" ]; then
  printf "    Lokale Snapshots: KEINE\n"
else
  printf "    Snapshot-Count:     $(echo "$snap" | /usr/bin/wc -l | /usr/bin/tr -d ' ')\n"
  printf "    Aeltestester:       $(echo "$snap" | /usr/bin/head -1)\n"
fi
/usr/sbin/diskutil apfs list 2>/dev/null | /usr/bin/grep -E "Name|Disk|Container|Capacity|Volume Name|Free Space" | /usr/bin/head -20

# =============================================================
#  [3] DISK Usage Heavyweights (Library + Home)
# =============================================================
section "3 · LIBRARY / HOME DISK-USE TOP 12"
printf "  Top 12 ~/Library:\n"
/usr/bin/du -sh "$H/Library/"* 2>/dev/null | /usr/bin/sort -h | /usr/bin/tail -12 | /usr/bin/sed 's/^/    /'

printf "\n  Top 12 Home dirs:\n"
/usr/bin/du -sh "$H/"*/ 2>/dev/null | /usr/bin/sort -h | /usr/bin/tail -12 | /usr/bin/sed 's/^/    /'

printf "\n  Top 12 Application Support (third-party):\n"
/usr/bin/du -sh "$H/Library/Application Support/"* 2>/dev/null | /usr/bin/sort -h | /usr/bin/tail -12 | /usr/bin/sed 's/^/    /'

# =============================================================
#  [4] MEMORY DETAIL
# =============================================================
section "4 · MEMORY DETAIL"
RAM_GB=$(( $(/usr/sbin/sysctl -n hw.memsize 2>/dev/null) / 1024 / 1024 / 1024 ))
_kv "Physical RAM"          "$RAM_GB GB"

printf "\n  [vm_stat 1s sample]:\n"
/usr/bin/vm_stat 2>/dev/null | /usr/bin/head -15 | /usr/bin/sed 's/^/    /'

printf "\n  [macOS activity monitor style]:\n"
top -l 1 -n 1 2>/dev/null | /usr/bin/grep -E "PhysMem|VM" | /usr/bin/sed 's/^/    /'

printf "\n  [Top 15 RAM-Hogs]:\n"
/bin/ps aux 2>/dev/null | /usr/bin/sort -nrk 4 | /usr/bin/head -16 | /usr/bin/awk 'NR>1 {printf "    %-7s %5s%%  %s\n", $2, $4, $11}' | /usr/bin/head -15

printf "\n  [Top 15 VSZ-Hogs (Virtual Size)]:\n"
/bin/ps aux 2>/dev/null | /usr/bin/sort -nrk 5 | /usr/bin/head -16 | /usr/bin/awk 'NR>1 {printf "    %-7s %6s MB  %s\n", $2, int($5/1024), $11}' | /usr/bin/head -15

# =============================================================
#  [5] CPU / LOAD / THERMAL
# =============================================================
section "5 · CPU / LOAD"
printf "  [top header Line]:\n"
/usr/bin/top -l 1 -n 1 2>/dev/null | /usr/bin/head -10 | /usr/bin/sed 's/^/    /'

printf "\n  [Top 15 CPU-Hogs]:\n"
/usr/bin/top -l 1 -n 15 2>/dev/null | /usr/bin/awk 'NR>=2 && $1 ~ /^[0-9]+$/ {printf "    PID=%-7s CPU=%s%% CMD=%s\n", $1, $3, $12}'

printf "\n  [Long-Running Cumulative CPU]:\n"
/bin/ps -Aco pid,time,comm 2>/dev/null | /usr/bin/sort -k2 -r | /usr/bin/head -10 | /usr/bin/awk '{printf "    PID=%-7s CPU-TIME=%s  CMD=%s\n", $1, $2, $3}'

# =============================================================
#  [6] DISK I/O / Open Files
# =============================================================
section "6 · DISK I/O / OPEN FILES"
printf "  [iostat 2s samples]:\n"
/usr/sbin/iostat -d -w 2 -c 2 2>/dev/null | /usr/bin/tail -5 | /usr/bin/sed 's/^/    /'

printf "\n  [Top 15 by open file count (lsof · limit 1000)]:\n"
/usr/sbin/lsof -nP 2>/dev/null | /usr/bin/awk 'NR>1 {n[$1]++} END {for (k in n) printf "    %-30s %d FDs\n", k, n[k]}' | /usr/bin/sort -nrk 2 | /usr/bin/head -15

# =============================================================
#  [7] POWER / pmset
# =============================================================
section "7 · POWER / pmset"
printf "  [pmset state]:\n"
/usr/bin/pmset -g 2>/dev/null | /usr/bin/sed 's/^/    /'

printf "\n  [Process-Assertions Sleep-Preventer]:\n"
/usr/bin/pmset -g assertions 2>/dev/null | /usr/bin/head -15 | /usr/bin/sed 's/^/    /'

printf "\n  [Recent Wake history]:\n"
/usr/bin/pmset -g history 2>/dev/null | /usr/bin/tail -10 | /usr/bin/sed 's/^/    /'

# =============================================================
#  [8] LAUNCHD JOBS
# =============================================================
section "8 · LAUNCHD JOBS"
_jobs=$(/bin/launchctl list 2>/dev/null | /usr/bin/wc -l | /usr/bin/tr -d ' ')
_kv "Aktive launchd-Jobs" "$_jobs jobs"

printf "\n  [User-Library LaunchAgents]:\n"
/bin/ls -lt "$H/Library/LaunchAgents/" 2>/dev/null | /usr/bin/awk 'NR>1 {printf "    %s %s %s %s\n", $6, $7, $8, $9}' | /usr/bin/head -25

printf "\n  [System-LaunchDaemons Count]:\n"
n_daemon=$(/bin/ls "/Library/LaunchDaemons/" 2>/dev/null | /usr/bin/wc -l | /usr/bin/tr -d ' ')
n_daemon_sys=$(/bin/ls "/System/Library/LaunchDaemons/" 2>/dev/null | /usr/bin/wc -l | /usr/bin/tr -d ' ')
printf "    /Library/LaunchDaemons:           %s\n" "$n_daemon"
printf "    /System/Library/LaunchDaemons:    %s\n" "$n_daemon_sys"

# =============================================================
#  [9] SPOTLIGHT + PHOTOANALYSIS
# =============================================================
section "9 · SPOTLIGHT / PHOTOANALYSED"
printf "  [Aktive Indizierungs-Prozesse]:\n"
/bin/ps axc -o pid,comm 2>/dev/null | /usr/bin/grep -E "mdworker|mdworker_shared|mds_stores|mdbulkimport|photoanalysisd" | /usr/bin/head -10 | /usr/bin/sed 's/^/    /'

printf "\n  [Spotlight Indexing Status]:\n"
/usr/bin/mdutil -s / 2>/dev/null | /usr/bin/sed 's/^/    /'

printf "\n  [Photos Library Size]:\n"
/usr/bin/du -sh "$H/Pictures/Photos Library.photoslibrary" 2>/dev/null

printf "\n  [photoanalysisd Verification]:\n"
/bin/launchctl print-disabled system/com.apple.photoanalysisd 2>/dev/null | /usr/bin/head -3 | /usr/bin/sed 's/^/    /' || echo "    (status unknown)"

# =============================================================
#  [10] PRIVACY / TCC / PERMISSIONS
# =============================================================
section "10 · PRIVACY / TCC / PERMISSIONS"
printf "  [Accessibility-Permission Apps]:\n"
/bin/ls "$H/Library/Application Support/com.apple.TCC/" 2>/dev/null | /usr/bin/head -10 | /usr/bin/sed 's/^/    /'
sqlite3="$H/Library/Application Support/com.apple.TCC/TCC.db"
if [ -f "$sqlite3" ]; then
  printf "\n  [Full-Disk-Access Apps]:\n"
  /usr/bin/sqlite3 "$sqlite3" "SELECT service, client FROM access WHERE service='kTCCServiceSystemPolicyFullDiskAccess' AND auth_value=2 LIMIT 20;" 2>/dev/null | /usr/bin/sed 's/^/    /' || echo "    (sqlite3 nicht verfügbar oder DB locked)"
  printf "\n  [Screen-Recording Apps]:\n"
  /usr/bin/sqlite3 "$sqlite3" "SELECT client FROM access WHERE service='kTCCServiceScreenCapture' AND auth_value=2 LIMIT 20;" 2>/dev/null | /usr/bin/sed 's/^/    /'
  printf "\n  [Microphone Access]:\n"
  /usr/bin/sqlite3 "$sqlite3" "SELECT client FROM access WHERE service='kTCCServiceMicrophone' AND auth_value=2 LIMIT 20;" 2>/dev/null | /usr/bin/sed 's/^/    /'
else
  echo "    (TCC.db not found at user level — try /Library/Application Support/com.apple.TCC/)"
fi

# =============================================================
#  [11] NETWORK / Bonjour / mDNSResponder
# =============================================================
section "11 · NETWORK / Bonjour"
printf "  [Aktive TCP/IP Connections (top 15 by State)]:\n"
/usr/bin/netstat -an -p tcp 2>/dev/null | /usr/bin/awk 'NR>1 {print $6}' | /usr/bin/sort | /usr/bin/uniq -c | /usr/bin/sort -rn | /usr/bin/head -8 | /usr/bin/sed 's/^/    /'

printf "\n  [Bonjour / mDNSResponder Active]:\n"
/bin/ps axc -o pid,comm 2>/dev/null | /usr/bin/grep -E "mDNSResponder|searchpartyd|biomesyncd" | /usr/bin/head -5 | /usr/bin/sed 's/^/    /'

# =============================================================
#  [12] PROCESS FAMILY FINGERPRINTING
# =============================================================
section "12 · PROCESS FAMILIES (klassisch-fingerprintbar)"
printf "  [Chromium-Family / Browser-Engines]:\n"
/bin/ps axc -o pid,comm 2>/dev/null | /usr/bin/grep -iE "chrome|chromium|brave|edge|firefox|opera|safari|arc" | /usr/bin/wc -l | /usr/bin/awk '{printf "    Count:    %s Prozesse\n", $1}'
/bin/ps axc -o pid,rss,comm 2>/dev/null | /usr/bin/grep -iE "chrome|chromium|brave|edge" | /usr/bin/awk '{sum+=$2; n++} END {if (n>0) printf "    RAM-Sum:  %s MB across %d procs\n", sum/1024, n}'

printf "\n  [Electron-Family (VSCode/Slack/Discord/Notion/…)]:\n"
/bin/ps axc -o pid,comm 2>/dev/null | /usr/bin/grep -iE "helper (renderer)|electron|\\\\bosascript\\\\b" | /usr/bin/wc -l | /usr/bin/awk '{printf "    Count:    %s Prozesse\n", $1}'

printf "\n  [Java / JVM Family]:\n"
/bin/ps axc -o pid,command 2>/dev/null | /usr/bin/grep -E "java|Java" | /usr/bin/wc -l | /usr/bin/awk '{printf "    Count:    %s java-Procs\n", $1}'

printf "\n  [Apple Hidden Daemons]:\n"
for d in coreduetd sharingd usbmuxd cupsd symptomsd feedbacklogger accessoryupdaterd ondeviceassistantd amsaccountsd findmydeviced privatecloud computertoolkit; do
  pid=$(/bin/launchctl print system 2>/dev/null | /usr/bin/grep -E "com.apple.${d}\b" | /usr/bin/head -1 | /usr/bin/awk '{print $1}')
  printf "    com.apple.%-22s  %s\n" "$d" "$pid"
done

# =============================================================
#  [13] KERNEL EXTENSIONS / THIRD-PARTY
# =============================================================
section "13 · KERNEL EXTENSIONS"
printf "  [Third-party kexts]:\n"
/usr/sbin/kmutil showloaded --no-kernel-components 2>/dev/null | /usr/bin/grep -v -E "com\.apple\." | /usr/bin/head -15 | /usr/bin/sed 's/^/    /'
printf "\n  [Deprecated / Legacy kern-extensions]:\n"
/usr/sbin/kextstat 2>/dev/null | /usr/bin/wc -l | /usr/bin/awk '{if ($1>5) printf "    Loaded kexts (multiple lines, may include third-party)\n"; else print "    (no third-party kexts/empty - good)"}' || echo "    (not available on Apple Silicon)"

# =============================================================
#  [14] SYSTEM INTEGRITY / GATEKEEPER
# =============================================================
section "14 · SYSTEM INTEGRITY"
printf "  [SIP]:\n"
/usr/bin/csrutil status 2>/dev/null | /usr/bin/sed 's/^/    /'
printf "\n  [Gatekeeper]:\n"
/usr/sbin/spctl --status 2>/dev/null | /usr/bin/sed 's/^/    /'
printf "\n  [FileVault]:\n"
/usr/bin/fdesetup status 2>/dev/null | /usr/bin/sed 's/^/    /'

# =============================================================
#  Footer Summary
# =============================================================
printf "\n============================================================\n"
printf "  END OF DEEP-DIAGNOSTIC\n"
printf "  Run: bash scripts/01-inventory.sh <profile>  for compact view\n"
printf "  Run: bash scripts/07-master-flow.sh <profile> --auto  for cleanup\n"
printf "============================================================\n"
