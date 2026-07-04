#!/usr/bin/env bash
# 07-master-flow.sh — orchestriert die 6 macos-cool Schritte.
# Use from the agent AS THE MAIN WIZARD: bash scripts/07-master-flow.sh
#
# Profile: passed via --profile=… flag.
# Mode:    --interactive | --auto (default = interactive)

set -euo pipefail

PROFILE="developer"
MODE="interactive"
for a in "$@"; do
  case "$a" in
    --profile=*) PROFILE="${a#--profile=}" ;;
    --auto) MODE="auto" ;;
    --interactive) MODE="interactive" ;;
  esac
done

H="$HOME"

printf "================ macos-cool · MASTER FLOW ================\n"
printf "Profile: %s\n" "$PROFILE"
printf "Mode:    %s\n" "$MODE"
printf "==========================================================\n\n"

printf "[1/7] Inventur (read-only)\n"
bash "$H/.config/opencode/scripts/01-inventory.sh" "$PROFILE" 2>/dev/null \
  || bash "$(dirname "$0")/01-inventory.sh" "$PROFILE"

printf "\n[2/7] Developer-Caches putzen\n"
case "$MODE" in
  interactive) bash "$(dirname "$0")/02-devcache-cleanup.sh" ;;
  auto)        bash "$(dirname "$0")/02-devcache-cleanup.sh" --yes ;;
esac

printf "\n[3/7] LaunchAgents (with confirmation)\n"
case "$MODE" in
  interactive) bash "$(dirname "$0")/03-launchagent-cleanup.sh" ;;
  auto)        bash "$(dirname "$0")/03-launchagent-cleanup.sh" --auto ;;
esac

printf "\n[4/7] System-Services (sudo-befehle an User ausgeben)\n"
bash "$(dirname "$0")/04-system-services-disable.sh"

printf "\n[5/7] Chrome Memory-Saver & Energy-Saver\n"
bash "$(dirname "$0")/05-chrome-memory-saver.sh"

printf "\n[6/7] Deep-Cleanup v0.2 — SavedState / Logs / Subsystems (15-21)\n"
case "$MODE" in
  interactive) bash "$(dirname "$0")/08-deep-cleanup.sh" "$PROFILE" ;;
  auto)        bash "$(dirname "$0")/08-deep-cleanup.sh" "$PROFILE" --auto ;;
esac

printf "\n[7/7] Validation\n"
/bin/df -h /System/Volumes/Data | /usr/bin/tail -1
/usr/bin/top -l 1 -n 1 | /usr/bin/head -5
/bin/launchctl list 2>/dev/null | /usr/bin/wc -l | /usr/bin/awk '{printf "  laufende launchd-Jobs: %s\n", $1}'

printf "\n============ macos-cool DONE (sudo-Teile manuell) ===========\n"
