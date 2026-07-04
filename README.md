# macOS-cool — Skill für opencode / claude-code

> **Fork my Mac from Apple bloat.** Der Skill-Agent erkennt, katalogisiert und entschärft:
>
> - Apple-System-Cruft (Spotlight, photoanalysisd, Time Machine, Telemetry)
> - Drittanbieter-Update-Agenten (Adobe ARM, Google Keystone, Microsoft AutoUpdater, JetBrains)
> - Antivirus-Bloat (TotalAV, Avast, Norton)
> - Crypto / Miner-Stubs (Grass, IP Royal)
> - Dev-Caches (npm, pnpm, yarn, pip, cargo, Maven, Playwright)
> - Browser-Cache (Chrome Caches / Profile-Inventur)

## Profile

Der Skill unterstützt 4 Profile (vom Agent zu Beginn ausgewählt):

- `developer-minimal` — nur Browser + 1 Editor + Terminal.
- `developer` — Browser + IDE + Dev-Tools. Apple-Bloat + Update-Agents weg.
- `power-user` — offensichtlicher Müll weg, Services je nach Bewertung.
- `privacy-paranoid` — alles + Telemetrie/Sync/Siri aus.

## Inhalt

| Datei | Zweck |
|---|---|
| `SKILL.md` | Hauptkatalog mit Prozedur, Tailwind-Catalog, Sicherheitsrules, Recovery. |
| `scripts/01-inventory.sh` | Read-only Inventur-Scan. |
| `scripts/02-devcache-cleanup.sh` | 100% reversible Dev-Caches wegputzen. |
| `scripts/03-launchagent-cleanup.sh` | Interaktive Bestellung pro LaunchAgent. |
| `scripts/04-system-services-disable.sh` | Druckt sudo-Befehle (User kopiert selbst). |
| `scripts/05-chrome-memory-saver.sh` | Chrome-Prefs: Memory Saver AN, Energy Saver AUS. |
| `scripts/06-undo-all.sh` | Reverse-Befehle für alles. |
| `scripts/07-master-flow.sh` | Orchestrator (alle 6 Schritte). |

## Verwendung als opencode-Skill

**Repo local clonen + in `opencode.json` aufnehmen:**

```bash
git clone https://github.com/OpenSIN-Code/macos-cool ~/dev/macos-cool
```

In `~/.config/opencode/opencode.json` (oder Project-`opencode.json`):

```json
{
  "skills": {
    "paths": ["~/dev/macos-cool"]
  }
}
```

Anschließend opencode neu starten.

## Verwendung als claude-code-Skill

```bash
git clone https://github.com/OpenSIN-Code/macos-cool ~/dev/macos-cool
ln -s ~/dev/macos-cool ~/.claude/skills/macos-cool
```

## Manuell aus dem Terminal

```bash
# 1. Inventur
bash scripts/01-inventory.sh developer

# 2. Dev-Caches (reversibel)
bash scripts/02-devcache-cleanup.sh --dry-run   # Vorschau
bash scripts/02-devcache-cleanup.sh --yes       # mit Confirm-Loop

# 3. LaunchAgents (interaktiv pro Item)
bash scripts/03-launchagent-cleanup.sh
# oder:
bash scripts/03-launchagent-cleanup.sh --auto --yes

# 4. System-Services (gibt sudo-Befehle aus)
bash scripts/04-system-services-disable.sh

# 5. Chrome (Chrome muss zu sein)
bash scripts/05-chrome-memory-saver.sh

# 6. master (alle Schritte)
bash scripts/07-master-flow.sh --profile=developer
```

## License

MIT. Issues / PRs willkommen.
