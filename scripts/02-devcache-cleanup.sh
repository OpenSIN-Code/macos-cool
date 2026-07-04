#!/usr/bin/env bash
# 02-devcache-cleanup.sh — Developer-Caches weg (zu 100% regenerierbar).
# Safe: kein Sudo nötig. KEINE privaten Pfade.
# Usage: bash scripts/02-devcache-cleanup.sh [--dry-run|--yes]

set -euo pipefail

DRY_RUN=0
[ "${1:-}" = "--dry-run" ] && DRY_RUN=1
[ "${1:-}" = "--yes" ]     && NO_CONFIRM=1

H="$HOME"
PATH_LIST=(
  # npm cache (user-scope)
  "$H/.npm/_cacache"
  "$H/.npm/_logs"
  # pnpm, yarn, bun, node-gyp, electron
  "$H/Library/Caches/pnpm"
  "$H/Library/Caches/yarn"
  "$H/Library/Caches/bun"
  "$H/Library/Caches/node-gyp"
  "$H/Library/Caches/electron"
  # Python
  "$H/Library/Caches/pip"
  "$H/.cache/pip"
  "$H/.cache/poetry"
  "$H/.conda/pkgs"
  # Rust / Cargo
  "$H/.cargo/registry/cache"
  "$H/.cargo/registry/src"
  # Go / Composer / PHP
  "$H/Library/Caches/go-build"
  "$H/Library/Caches/composer"
  # TS / LSP / Bundler / Playwright
  "$H/Library/Caches/typescript"
  "$H/Library/Caches/gopls"
  "$H/Library/Caches/.lingma"
  "$H/Library/Caches/next-swc"
  "$H/Library/Caches/ms-playwright"
  "$H/Library/Caches/ms-playwright-go"
  # bun install-cache
  "$H/.bun/install/cache"
  # Xcode build
  "$H/Library/Developer/Xcode/DerivedData"
)

# USE python cache-purge where recognized
before_total=$(/usr/bin/du -sh "${PATH_LIST[@]}" 2>/dev/null | /usr/bin/awk '{sum+=$1} END {print "n/a"}')
echo "Gesamt-Schaetzung (one-shot) vor Putzen:"

total=0
echo ""
printf "  %-58s %8s\n" "PATH" "GROESSE"
/usr/bin/printf "  %-58s %8s\n" "---------------------------------------------- ----------"
for p in "${PATH_LIST[@]}"; do
  if [ -e "$p" ]; then
    sz=$(/usr/bin/du -sh "$p" 2>/dev/null | /usr/bin/awk '{print $1}')
    printf "  %-58s %8s\n" "$p" "$sz"
    bytes=$(/usr/bin/du -sb "$p" 2>/dev/null | /usr/bin/awk '{print $1}')
    total=$(( total + bytes ))
  fi
done
total_mb=$(( total / 1024 / 1024 ))
printf "  %-58s %8s MB\n" "TOTAL (Sum bytes)" "$total_mb"

if [ "${DRY_RUN:-0}" = "1" ]; then
  echo ""
  echo "(DRY-RUN) — keine Löschung."
  /usr/bin/du -sh "${PATH_LIST[@]}" 2>/dev/null
  exit 0
fi

if [ "${NO_CONFIRM:-0}" != "1" ]; then
  echo ""
  printf "Wirklich alle diese Developer-Caches löschen? Tippe 'yes' oder Ctrl-C: "
  read -r ans
  [ "$ans" = "yes" ] || { echo "Abbruch."; exit 1; }
fi

echo ""
echo "Starte Cleanup..."

# Spezielle Pflege-Befehle
[ -d "$H/.npm" ] && /usr/bin/find "$H/.npm" -depth -delete 2>/dev/null || true
/usr/local/bin/brew cleanup -s --prune=all 2>/dev/null || /usr/bin/true
[ -d "$H/Library/Caches/pip" ] && /usr/bin/find "$H/Library/Caches/pip" -depth -delete 2>/dev/null
[ -d "$H/.cache/pip" ] && /usr/bin/find "$H/.cache/pip" -depth -delete 2>/dev/null

for p in "${PATH_LIST[@]}"; do
  [ -e "$p" ] || continue
  case "$p" in
    *pip*|*npm*)
      # schon oben behandelt
      ;;
    *)
      /usr/bin/find "$p" -depth -delete 2>/dev/null
      ;;
  esac
done

echo ""
echo "Cleanup fertig. Aktueller Stand:"
/bin/df -h /System/Volumes/Data | /usr/bin/tail -1
