# macOS-cool — Skill für opencode / claude-code

> **Fork my Mac from Apple bloat.** Der Skill-Agent erkennt, katalogisiert und entschärft macOS-Bloat in 7 Klassen mit Bestätigungs-Wizard und 4 User-Profilen.
>
> **Umfang v0.3:** ~50 KB SKILL.md (25 Sektionen), 9 Shell-Skripte, MIT-Lizenz. Stand: macOS 26.5.1.

## Was deckt der Skill ab?

| Klasse | Beispiele |
|---|---|
| **A · Apple System-Cruft** | Spotlight, photoanalysisd, Time Machine, Telemetrie, iCloud Sync, Siri |
| **B · Third-Party Update-Agents** | Adobe ARM/ARMDC, Google Keystone, Microsoft AutoUpdater, JetBrains Toolbox, Epic, MEGA, AWS CodeWhisperer, NotebookLM |
| **C · Antivirus/Crypto** | TotalAV, Avast, Norton (Free-Versionen = kein echter Schutz). Grass (`io.getgrass.desktop`), IP Royal Paws |
| **D · Dev-Caches** | npm, pnpm, yarn, bun, pip, conda, Rust toolchain via `rustup cache`, Go build cache, Composer, ms-playwright, … |
| **E · Browser-Caches** | Chrome Profile-Caches (Logins bleiben erhalten!), Firefox, Brave, Edge |
| **F · Hidden Apple Subsystems** | `coreduetd` (Handoff), `sharingd` (AirDrop), `usbmuxd` (USB-Tether), `cupsd` (Printing), `symptomsd` (Apple-Reports), `feedbacklogger`, `accessoryupdaterd` (AirPods-FW), `ondeviceassistantd` (Siri on-device), `amsaccountsd` |
| **G · Specialty-Caches** | Saved Application State (Slack/Discord/VSCode-Saves, 1–5 GB!), Logs >30 Tage, Notification-DB, Personal-App-Caches (Spotify/WhatsApp/Zoom/Telegram), FCP-Workflow, Minecraft-Webcache |

## Profile (4 vom Agent auswählbar)

| Profil | Use-Case | Was wird genommen |
|---|---|---|
| `developer-minimal` | Nur Browser + 1 Editor + Terminal. | Alles außer Browser & 1 Editor. Kein Photos, kein Mail, kein iCloud. |
| `developer` | Programmierer-Setup. | Apple-Bloat + Update-Agents + Dev-Caches. |
| `power-user` | bewusste Nutzung einzelner Dienste. | offensichtlicher Müll + AV (Free) + Update-Agents. iCloud nur auf Confirm. |
| `privacy-paranoid` | Anti-Tracking durch Apple. | alles + Telemetrie/Sync/Siri/iCloud/Analytics aus. |

## Quick Start

### 1 · Repo local clonen

```bash
git clone https://github.com/OpenSIN-Code/macos-cool ~/dev/macos-cool
```

### 2 · in `opencode.json` einbinden

**Option A · global** (`~/.config/opencode/opencode.json`):

```json
{
  "skills": {
    "paths": ["~/dev/macos-cool"]
  }
}
```

**Option B · pro Projekt** (`<project>/opencode.json` im Worktree-Root):

```json
{
  "$schema": "https://opencode.ai/config.json",
  "skills": {
    "paths": ["~/dev/macos-cool"]
  }
}
```

**Option C · per URL (kein lokaler Clone nötig)**:

```json
{
  "skills": {
    "urls": ["https://raw.githubusercontent.com/OpenSIN-Code/macos-cool/main/SKILL.md"]
  }
}
```

### 3 · opencode neu starten

Config wird beim Start geladen, nicht hot-reloaded. Siehe SKILL.md §„Applying changes".

### 4 · Skill auslösen

Der Skill matcht auf Trigger-Keywords. Ein paar Beispiele:

- „Mac ist lahm" / „warum 28 Load Avg"
- „Spotlight wütet" / „fotoanalyse aus"
- „Time Machine sichert und ich will das nicht"
- „Adobe Helper löschen" / „jetbrains weg" / „megas updater weg" / „antivirus müll"
- „grass ist dreck" / „notebooklm daily aus"
- „wie deaktiviere ich Spotlight"
- „Developer-Mini-Profile"
- „macos-cool" / „macos cool machen"
- „bloat entfernen"

## Scripts im Repo

| Skript | Zweck |
|---|---|
| `scripts/01-inventory.sh` | Read-only Inventur-Scan. |
| `scripts/02-devcache-cleanup.sh` | 100 % reversible Dev-Caches (`npm`, `pnpm`, `pip`, `Cargo`, …). |
| `scripts/03-launchagent-cleanup.sh` | Interaktive Bestätigung pro LaunchAgent (~30 Einträge). |
| `scripts/04-system-services-disable.sh` | Druckt sudo-Befehle (User kopiert in Terminal). |
| `scripts/05-chrome-memory-saver.sh` | Schreibt `performance.memory_saver_mode.enabled=true`, `energy_saver_mode.enabled=false` in alle Chrome-Profile-Prefs. |
| `scripts/06-undo-all.sh` | Reverse-Befehle für alles (Spotlight, photoanalysisd, TM, …). |
| `scripts/07-master-flow.sh` | Orchestrator mit 7 Steps. |
| `scripts/08-deep-cleanup.sh` | **v0.2** — SavedState-Sweep, Logs >30 Tage, Notification-DB, Personal-App-Cache, Font/QuickLook. |
| `scripts/09-specialty-cleanup.sh` | **v0.3** — PDF/OCR, AirPort-Legacy, Mail-Plugins, Thunderbolt/eGPU, FCP, Minecraft. |
| `scripts/10-deep-diagnostic.sh` | **v0.4** — Komplettes System-Audit (14 Sektionen: Disk/Memory/CPU/IO/Power/Network/Privacy/Spotlight/Photoanalysis/APFS/TCC/Kernel-Extensions/Process-Families). |
| `scripts/11-app-catalog-wizard.sh` | **v0.4** — App-Katalog-Tabelle aller GUI-Apps mit Risiko-Klasse + Suggested-Action. Per-App-Bestätigungs-Wizard. |

## Manual aus dem Terminal

```bash
cd ~/dev/macos-cool

# 1. Inventur
bash scripts/01-inventory.sh developer            # profile = developer|developer-minimal|power-user|privacy-paranoid

# 2. Dev-Caches (Vorschau / Bestätigung)
bash scripts/02-devcache-cleanup.sh --dry-run
bash scripts/02-devcache-cleanup.sh --yes

# 3. LaunchAgents (Step-by-Step oder Auto)
bash scripts/03-launchagent-cleanup.sh
bash scripts/03-launchagent-cleanup.sh --auto --yes

# 4. System-Services (sudo)
bash scripts/04-system-services-disable.sh

# 5. Chrome (Chrome vorher schliessen!)
osascript -e 'tell application "Google Chrome" to quit'
bash scripts/05-chrome-memory-saver.sh
open -a "Google Chrome"

# 6. Master Flow
bash scripts/07-master-flow.sh --profile=developer --auto
```

## Verwendung in claude-code

```bash
git clone https://github.com/OpenSIN-Code/macos-cool ~/dev/macos-cool
ln -s ~/dev/macos-cool ~/.claude/skills/macos-cool          # symlink
# requires SKILL.md at root — it is. Done.

# Hardlink oder echter Clone in ~/.claude/skills/macos-cool:
mkdir -p ~/.claude/skills && cp -R ~/dev/macos-cool ~/.claude/skills/macos-cool
```

## Versionen — Versions-Historie

- **v0.1** — Initial: Catalog Classes A–E + 7 Scripts.
- **v0.2** — Class F (Hidden Apple Subsystems) + State/Logs/PersonalApps/Notification/pmset (§15–§21) + script `08-deep-cleanup.sh`.
- **v0.3** — `pmset` Detail (§23) + 6 Specialty-Caches (§24: PDF/OCR, AirPort, Mail-Plugins, Thunderbolt/eGPU, FCP, Minecraft) + script `09-specialty-cleanup.sh`.

## Lizenz

MIT — Issues / PRs willkommen auf <https://github.com/OpenSIN-Code/macos-cool>.

## Mitmachen

Issues mit Repro-Steps:
- macOS-Version + Build-Nummer (`sw_vers`)
- Hardware (Modell + RAM)
- `bash scripts/01-inventory.sh <profile>` Output
- Welche Schritte, welche Effekte

PRs: bitte Repro + Vorher-/Nachher-Diagnose anhängen.
