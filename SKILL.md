---
name: macos-cool
description: Use when the user complains about macOS performance, wants to free disk/CPU, asks to remove Apple "bloat" (Spotlight agents, photoanalysisd, Time Machine auto-snapshots, Apple telemetry), wipe third-party auto-update agents (Adobe ARM/ARMDC, Google Keystone, Microsoft AutoUpdater, JetBrains Toolbox, Epic, MEGA, Crypto miners like Grass/royal-paws), disable antivirus remnants (TotalAV, Norton), or clean dev caches (npm/pnpm/yarn/bun/pip, Go, Rust, Composer, Playwright, TypeScript, Electron). Asks the user before every destructive action and exposes four pre-canned profiles (developer-minimal, developer, power-user, privacy-paranoid). Triggers include: "mac ist lahm", "warum läuft Spotlight", "photoanalysisd weg", "Time Machine aus", "Adobe Helper löschen", "JetBrains weg", "Antivirus Müll", "Grass weg", "MEGA löschen", "Entwickler-Mac", "macos cool machen", "macos-cool", "bloat entfernen", "Mac aufgeben", "Mac zu langsam", "macos cooler machen", "wie deaktiviere ich Spotlight".
license: MIT
metadata:
  author: OpenSIN-Code
  topic: macos-debloating, system-optimisation
  audience: opencode / claude-code / generic AI agent
  sources: opencode session 2026-07-04 (Delqhi), Apple developer docs, MIT/LGPL open-source insider knowledge, James Dempsey "system-cruft" public notes, Howard Hinnant "lldb free" pages, EclecticLight.com
---

# macOS-cool — befreie den Mac von Apple-Dreck

> **Skill-Policy:**
> 1. **Bestätigung vor jeder Zerstörung.** Der Agent fragt pro Item.
> 2. **Reversibel wo möglich.** Skripte haben einen `undo`-Pfad.
> 3. **Backup-First.** Niemals `~/Library/Mail`, `~/Library/Notes`, `~/Library/Messages`, `~/Library/Photos Library*`, `~/.ssh/`, Keychain ohne Time-Machine-Snapshot oder explizites User-OK.
> 4. **Privat-Invariant.** `~/Documents`, `~/Desktop`, `~/Downloads`, `~/Pictures`, `~/Movies`, `~/Music`, Backup-Sticks, `~/*.zip` mit persönlichen Inhalten — niemals anfassen ohne User-Aufruf.
> 5. **Sudo-Sachen getrennt listen.** Der Agent führt sie NICHT remote aus, wenn der User keinen PW-Pfad eingerichtet hat. Stattdessen: Skript-Block zum Copy-Paste in Terminal.app.

---

## 0 · Trigger dieses Skills

Lade diesen Skill, wenn der User:

- „Mac ist lahm seit wir die Caches gelöscht haben" / „warum 28 Load Avg bei 16 Cores"
- „Spotlight wütet" / „photoanalysisd weg" / „Time Machine sichert und ich will das nicht"
- „Adobe Helper löschen" / „JetBrains weg" / „MEGA Updater" / „Grass" / „Epic Games Launcher"
- „Antivirus Free-Version ist eh kein Schutz" (TotalAV, Avast, Norton)
- „wie viel GB braucht Chrome?" / „Chrome: was kann man löschen ohne meine Logins?"
- „brauche nur Browser + Editor" / „Developer-Minimal-Profil"
- „macos-cool" / „apple dreck" / „apple müllt voll"
- ein Symptom passt: `Load Avg > Cores × 1.5`, hohe RAM-Compressor, APFS fast voll, langsame Suche

---

## 1 · User-Profile (Agent fragt zu Beginn)

Der Agent muss ZUERST eines dieser vier Profile wählen. Die Auswahl bestimmt den Default-Scope — der User kann pro Item trotzdem individuell widersprechen.

| Profil | Definition | Default-Aktion |
|---|---|---|
| **`developer-minimal`** | nur Safari/Chrome + 1 Editor + Terminal. **Maximaler Speicher & CPU freigeben.** | ALLES weg bis auf: Kernel, Window-Server, 1 Browser, 1 Editor. Kein Mail, keine Photos, keine Notizen, keine iCloud, kein Drucker. |
| **`developer`** | Programmierer, der mit Browser, IDE/Slack/Notion/Hermes/SINator arbeitet. | Apple-Bloat weg. Drittanbieter-Update-Agenten weg. AV weg. Dev-Caches weg + wöchentliches Cleanup-Hook. |
| **`power-user`** | MacOS mit Tools bewusst benutzen, nicht alle Standarddienste wollen. | Apple-Bloat individuell. Drittanbieter-Update-Agenten weg. AV weg falls Free. Dev-Caches weg. |
| **`privacy-paranoid`** | Telemetrie + iCloud + Apple-Advertising aus. | ALLES von `developer` + `analyticsd`, `dprivacyd`, `bird`, `cloudd`, `netbiosd`, `findmydeviced` disabled. Siri-Datenbank gelöscht. |

### So fragt der Agent

```
Ich starte macos-cool mit Profil-Wahl.

(1) developer-minimal  — nur Browser + 1 Editor. Maximaler Speicher & CPU.
(2) developer          — Browser + IDE + Dev-Tools. Apple-Bloat + Update-Agents weg.
(3) power-user         — was offensichtlich Müll ist, weg.
(4) privacy-paranoid   — zusätzlich Telemetrie/Sync/Siri aus.

Welches Profil? (1/2/3/4 oder "stop")
```

---

## 2 · Bestätigungs-Wizard (Step-by-Step Flow)

### Step A · Inventur-Scan (lesen, nicht löschen)

```bash
# 1. Wo sitzen die Schwergewichte?
du -sh ~/Library/* 2>/dev/null | sort -h | tail -10
du -sh ~/* 2>/dev/null | sort -h

# 2. Was läuft im Hintergrund?
launchctl list | wc -l                                       # wie viele Jobs?
launchctl list | grep -E "user/$(id -u)" | head -30         # User-Jobs
ls ~/Library/LaunchAgents/                                   # User-Autostart
ls /Library/LaunchAgents/                                    # System-Autostart (root)
ls /Library/LaunchDaemons/ | wc -l                           # System-Daemons (root)

# 3. Was ist aktuell am meisten Last?
top -l 1 -n 15                                               # CPU top
ps aux | sort -nrk 4 | head -15                              # RAM top

# 4. Wo klemmt der Disk?
df -h /System/Volumes/Data
iostat -d -w 2 -c 2
```

### Step B · Item-Catalog anzeigen

Der Agent präsentiert eine Tabelle aus den Catalogs in §3–§7. Jede Zeile hat:

- `LABEL` — kurze ID
- `WHAT` — Apple-Bloat, Update-Agent, Browser-Cache, Dev-Cache
- `WHERE` — Pfad(e)
- `SIZE` — aktuelle Größe (vom `du`-Scan)
- `PRIVATE?` — 🔴 Daten / 🟠 Gemischt / 🟢 Cache / ⚪ Policies

### Step C · Bestätigungs-Loop

Für jedes Item, das gelöscht/deaktiviert werden soll, fragt der Agent einzeln:

```
[1/47] Adobe ARM Helper (LaunchAgent + 2 LaunchDaemons, ~70 MB)
   → LÖSCHEN? [y/N/keep-all/skip-rest/analyze more]
```

**Default-Antwort ist N**, wenn der User schweigt. Wer „fire-all" eingibt, fährt das gesamte Profil-Script durch.

### Step D · Execution

Es gibt **ZWEI Modi**:

- **Manuell**: Der Agent zeigt pro Item den Befehl, der User kopiert und führt aus.
- **Skript**: Der Agent schreibt ein Cleanup-Skript (`scripts/cleanup-<profile>-<date>.sh`), das der User ausführt.

> **Empfehlung:** Skript-Modus mit `set -euo pipefail` und einem **PREVIEW-Pass** (`echo rm -rf …` statt `rm -rf …`), den der User nochmal ansieht.

### Step E · Validierung

```bash
# nach Ausführung: Was hat sich verändert?
df -h /System/Volumes/Data
top -l 1 -n 15                                  # Load Avg & CPU
launchctl list | wc -l                           # weniger Jobs?
mdfind -count .                                 # Spotlight noch interessant?
tmutil status                                    # Time Machine aktiv?
```

### Step F · Restart-Test

Manche deaktivierten Dienste wirken erst nach Reboot oder `launchctl bootout user/$$` + Login. Der Agent sagt explizit, was nach Reboot wirkt vs. was sofort passiert.

---

## 3 · Apple System-Cruft (Klasse A)

> Diese Dienste laufen ab Werk und brauchen macOS nicht zwingend. Je nach Profil sind sie „okay" oder „abschalten".

### 3.1 Spotlight (mdworker / mds_stores / mdbulkimport)

| Was | Pfad / Befehl | Warum Bloat |
|---|---|---|
| Spotlight-Indizierung an/aus | `sudo mdutil -a -i off` / `on` | Re-indiziert nach jeder Filesystem-Änderung. Nach 50 GB Cleanup = 100 % CPU für Stunden. |
| Forced bulk-import-Resume | `sudo mdutil -a -E` | Erzwingt komplette Neu-Indizierung. NICHT als Daily-Tool. |
| Spotlight-Vorschläge (Web) | Safari → Settings → Search → disable | Sendet Queries an Apple. |
| Spotlight-User-Activity | `~/Library/Application Support/com.apple.spotlight` | Local history. |

**Konsequenz bei aus:**
- Cmd+Space → Datei-Suche funktioniert nicht mehr (die System-Settings-Suche funktioniert noch)
- Mail.app-Suche: langsam (Index fehlt)
- Photos.app-Suche: langsam
- Quick-Look-Vorschau bleibt funktional

**Reversibel:** `sudo mdutil -a -i on`.

### 3.2 photoanalysisd (Photos AI / Face-Recognition)

| Was | Befehl |
|---|---|
| Service deaktivieren | `sudo launchctl disable system/com.apple.photoanalysisd` |
| Library komplett weg | Photos.app öffnen → Library → „Delete Library…" |
| Face-Recognition in Photos | Photos.app → Settings → „Use facial recognition" OFF |
| Personen-DB weg | `~/Library/Photos Library.photoslibrary` (groß!) |

> ⚠️ Wenn `photoanalysisd` SIP-geschützt ist (aktuelle macOS-Versionen), nur deaktivieren, nicht löschen. Die Library-DB selbst ist löschbar via Photos.app.

### 3.3 Time Machine (backupd + backupd-helper)

| Was | Befehl | Effekt |
|---|---|---|
| Status sehen | `tmutil status` | läuft Park? Was sichert gerade? |
| Auto-Backup aus | `sudo tmutil disable` | keine Snapshots mehr, kein Auto-Backup |
| Auto-Backup an | `sudo tmutil enable` | reaktiviert |
| Lokale Snapshots anzeigen | `tmutil listlocalsnapshots /` | |
| Snapshot löschen (einzeln) | `sudo tmutil deletelocalsnapshots <YYYY-MM-DD-HHMMSS>` | APFS-Snapshot weg |
| Ziel ausschließen | `sudo tmutil addexclusion <path>` | ein Pfad nicht sichern |

**Konsequenz bei lokaler TM:**
- Ohne externe Disk: nur APFS-Snapshots, die mit jeder System-Aktion mehr Platz fressen
- Snapshots nicht löschbar über Finder → nur via `tmutil`

### 3.4 Telemetrie & Differential Privacy

| Dienst | Was tun |
|---|---|
| `com.apple.analyticsd` | Telemetry-Collector. `sudo launchctl disable system/com.apple.analyticsd` |
| `com.apple.dprivacyd` | Differential Privacy. `sudo launchctl disable system/com.apple.dprivacyd` |
| `com.apple.feedbacklogger` | System-Logs nach Apple (anonymisiert). Deaktivierbar. |
| `com.apple.SubmitDiagInfo` | Auto-Submit crash reports. `defaults write com.apple.CrashReporter AutoSubmit -bool false` |

### 3.5 iCloud Sync-Anker (`cloudd`, `bird`, `findmydeviced`, `parsec-feb`)

| Dienst | Effekt deaktivieren |
|---|---|
| `cloudd` | iCloud Drive Sync weg. ⚠️ Wenn aktiv, lokale Files könnten betroffen sein. |
| `bird` | iCloud Drive IO-Loop (background), Backup of synced files. |
| `findmydeviced` | „Find My Mac" Updates weg. Im Verlustfall tot. |
| `parsec-feb` | Spotlight-Parsing Bundle Cache (Bacon-Apple-Tool). |
| `netbiosd` | SMB-Browser. Nur deaktivieren wenn keine SMB-Shares. |
| `biomesyncd` | Biomes-Background-Sync für iCloud Game Save. |

### 3.6 Werbe-/Siri-Layer

| Was | Befehl |
|---|---|
| Apple-Ads aus | `defaults write com.apple.AppleAccount Ad Targeting Opt-Out -bool YES` |
| Siri-Vorschläge aus | `defaults write com.apple.Siri SuggestionsEnabled -bool false` |
| Siri-Datenbank löschen | `defaults delete com.apple.Siri` (reset, dann neu) |
| Logging aus | `sudo log config --mode "level: error"` (Log-Reduktion) |

### 3.7 Login-Items (AutoLaunch)

```bash
# User-Login-Items listen
osascript -e 'tell application "System Events" to get the name of every login item'
# Löschen:
osascript -e 'tell application "System Events" to delete login item "<Name>"'
```

---

## 4 · Drittanbieter-Update-Agenten (Klasse B)

Fast jede App installiert einen Background-Updater. Die sind offensichtlicher Müll, weil die App weg ist und der Updater weiterlaufen darf.

### 4.1 Adobe (`com.adobe.*`)

| Pfad | Befehl |
|---|---|
| `~/Library/Application Support/Adobe` (31+ MB Cache) | `rm -rf` |
| `~/Library/Application Support/com.adobe.dunamis` (70 MB drosseln/cloud) | `rm -rf` |
| `~/Library/Caches/Adobe` | `rm -rf` |
| `~/Library/Caches/com.adobe.dunamis` | `rm -rf` |
| `~/Library/Preferences/Adobe/*` (kompletter Ordner) | `rm -rf` |
| `~/Library/Preferences/com.adobe.*.plist` | `rm -f` |
| `/Library/LaunchAgents/com.adobe.ARMDCHelper.*.plist` | `sudo rm -f` |
| `/Library/LaunchDaemons/com.adobe.ARMDC.Communicator.plist` | `sudo rm -f` |
| `/Library/LaunchDaemons/com.adobe.ARMDC.SMJobBlessHelper.plist` | `sudo rm -f` |

### 4.2 JetBrains (`com.jetbrains.*`)

| Pfad | Was |
|---|---|
| `~/Library/LaunchAgents/com.jetbrains.toolbox.plist` | Toolbox Auto-Update |
| `~/Library/Application Support/JetBrains` (124 KB) | IDE-State |
| `~/Library/Application Support/JetBrains Space` (1,2 MB) | Cloud-Workspace |
| `~/Library/Preferences/com.jetbrains.*.plist` (PhpStorm, Space, Toolbox, Fleet) | Settings |
| `~/.config/JetBrains/`, `~/.local/share/JetBrains/` (falls vorhanden) | per-app configs |
| `~/Library/Caches/JetBrains/*` | Cache |

**Außerdem:** Wenn eine JetBrains-IDE nicht mehr benutzt wird:
```bash
rm -rf ~/Library/Application Support/<JetBrainsApp>{,EAP,CE}
rm -rf ~/Library/Caches/<JetBrainsApp>{,EAP,CE}
rm -rf ~/Library/Logs/<JetBrainsApp>{,EAP,CE}
```
(Beispiel: IntelliJ, GoLand, WebStorm, PhpStorm, CLion, RubyMine, Rider, PyCharm, AppCode, RustRover)

### 4.3 Google (`com.google.*`)

| Pfad | Befehl |
|---|---|
| `~/Library/LaunchAgents/com.google.keystone.agent.plist` | Chrome-Updater |
| `~/Library/LaunchAgents/com.google.keystone.xpcservice.plist` | Chrome-Updater |
| `~/Library/LaunchAgents/com.google.GoogleUpdater.wake.plist` | Wake-up Updater |
| `~/Library/Application Support/Google/GoogleUpdater` (700+ MB) | Update-Pakete |
| `~/Library/Caches/com.google.GoogleUpdater` | Update-Cache |
| `~/Library/Caches/com.google.GoogleDriveFS` | Drive-Cache |
| `/Library/LaunchDaemons/com.docker.*` (Docker Desktop nutzt für VM) | nur mit `docker` |

> Wenn Chrome benutzt wird, KEIN kompletter Google-Block löschen — `keystone` ist nicht zwingend, Chrome updated sich auch ohne Helper.

### 4.4 Microsoft (`com.microsoft.*`)

| Pfad | Was |
|---|---|
| `~/Library/LaunchAgents/com.microsoft.update.agent.plist` | Office-Updater |
| `~/Library/LaunchAgents/com.microsoft.Office365ServiceV2.plist` | Office-Background |
| `~/Library/Application Support/Microsoft/` | Settings |
| `~/Library/Caches/com.microsoft.edgemac*` (Edge-Browser) | Edge Cache |
| Installierte Apps: `Microsoft Word.app`, `Excel.app`, `Outlook.app`, `PowerPoint.app`, `OneDrive.app`, `Microsoft Teams.app` | |

### 4.5 Epic Games / Steam / EA / Battle.net

| Vendor | Launcher-Plist |
|---|---|
| Epic | `~/Library/LaunchAgents/com.epicgames.launcher.plist` (nur wenn Launcher-Cache) |
| Steam | `~/Library/Application Support/Steam`, `~/Library/Caches/com.valvesoftware.steam.helper` |
| EA | `~/Library/LaunchAgents/com.ea.origin.Client.plist` (Origin) |
| Battle.net | `~/Library/Application Support/Battle.net` |

### 4.6 Cloud-Sync-Launcher

| Dienst | Pfad |
|---|---|
| **MEGA** | `~/Library/LaunchAgents/mega.mac.megaupdater.plist`, `~/Library/Application Support/Mega Limited` |
| **Dropbox** | `~/Library/Application Support/Dropbox`, `~/Library/Caches/com.getdropbox.dropbox` |
| **TeraBox / Dubox** | `~/Library/Containers/com.dubox.drive` |
| **Google Drive** | `~/Library/Application Support/Google/DriveFS` (kein eigener LaunchAgent, in Chrome Updater) |
| **OneDrive** | `~/Library/Caches/com.microsoft.OneDrive` |
| **iCloud Drive** | `~/Library/Mobile Documents/com~apple~CloudDocs` |

### 4.7 Crypto / Mining / Eigenversuche

| Tool | Pfad |
|---|---|
| **Grass (`io.getgrass.desktop`)** | `~/Library/LaunchAgents/Grass.plist`, `~/Library/Application Support/ip_royal_paws/`, `~/Library/Preferences/io.getgrass.desktop.plist` |
| **Honeyminer / Cudo / NiceHash** | eine Suche nach `~/Library/Application Support/{honeyminer,cudo,nicehash}` |
| **Salad.io** | `salad.io` Filename |
| **Royal Paws / IP Royal** | `~/Library/Application Support/ip_royal_paws/` |

### 4.8 AV / Sicherheit (Free-Version ohne echten Schutz)

| App | Pfad |
|---|---|
| **TotalAV** | `~/Library/Application Support/net.protected.macos.TotalAV`, `~/Library/Preferences/net.protected.macos.TotalAV.plist`, `/Library/LaunchDaemons/net.protected.macos.AVHelper.plist` |
| **Avast** | `~/Library/Application Support/Avast` |
| **AVG** | `~/Library/Application Support/AVG` |
| **Norton** | `~/Library/Application Support/Norton Solutions` |
| **Bitdefender** | `~/Library/Application Support/Bitdefender` |
| **McAfee** | `~/Library/Application Support/McAfee` |

> **Realitäts-Check:** macOS hat eine eigene Malware-Defense (`XProtect` / `Gatekeeper`). Free-Versionen der oben genannten Tools bieten keinen Mehrwert. → **Standardmäßig weg bei `power-user` und `developer-minimal`.**

### 4.9 AI/Productivity-Launcher-Helpers

| App | Pfad |
|---|---|
| **NotebookLM** | `~/Library/LaunchAgents/com.aiometrics.notebooklm.daily.plist` |
| **AWS CodeWhisperer** | `~/Library/LaunchAgents/com.amazon.codewhisperer.launcher.plist` (meist in IDE-Extension — nicht separate App) |
| **Tabnine** | meist als VS-Code-Extension, kein eigener Helper |
| **PearAI / Cursor / Void** | als Electron-Apps → siehe §5 |

---

## 5 · Browser-Caches (Klasse C)

> **Wichtig:** Hier werden nur CACHE-Ordner gelöscht — niemals Bookmarks / Login Data / Cookies / Local Storage / IndexedDB / Extensions. Die User-Logins bleiben!

### 5.1 Chrome (`~/Library/Application Support/Google/Chrome/<Profil>/`)

**Profile finden:**
```bash
ls ~/Library/Application Support/Google/Chrome/ | grep -E "^Default$|^Profile"
```

**Safe-to-delete Cache-Ordner pro Profil** (alle regenerieren sich):
- `Cache/`, `Code Cache/`, `GPUCache/`, `GraphiteDawnCache/`, `DawnGraphiteCache/`, `DawnWebGPUCache/`, `GrShaderCache/`, `ShaderCache/`
- `component_crx_cache/`, `extensions_crx_cache/`
- `Service Worker/CacheStorage/`, `Service Worker/ScriptCache/`
- `optimization_guide_model_store/`, `optimization_guide_hint_cache_store/`
- `Favicons/` (Browser-Bildchen-DB)
- `Shared Dictionary/`, `ZxcvbnData/`, `Safe Browsing/`, `WasmTtsEngine/`
- `Reporting and NEL/`, `DIPS-wal/`, `ActorSafetyLists/`
- `AutofillAiModelCache/`, `AutofillStrikeDatabase/`

**NICHT anfassen** (User-Logins + Daten):
- `Bookmarks`, `Bookmarks.bak`, `History`, `Login Data`
- `Cookies`, `Cookies-journal`
- `Web Data`, `Account Web Data`, `Affiliation Database`
- `Local Storage/`, `Session Storage/`, `IndexedDB/`
- `Preferences`, `Secure Preferences`, `Sync Data`
- `Extensions/`, `Local Extension Settings/`
- `Service Worker/Database/` (Web-App-State, nicht Cache)
- `Profile 1–102/` falls vorhanden (jeder ist ein Profil, manche Bot-Profile = kann weg, andere = User-Profile)

**Chrome Memory-Saver / Energy-Saver setzen** (alle Profile):
1. Chrome komplett schließen (`Cmd+Q` auf jedem Fenster).
2. JSON-Prefs pro Profil editieren:
   ```bash
   P="$HOME/Library/Application Support/Google/Chrome"
   for f in "$P/Default/Preferences" "$P/Profile "*/Preferences ; do
     /usr/bin/python3 -c "
   import json, sys
   p = '$f'
   with open(p) as fh: d = json.load(fh)
   d['performance']['memory_saver_mode']['enabled'] = True
   d['performance']['energy_saver_mode']['enabled'] = False
   with open(p, 'w') as fh: json.dump(d, fh)
   " 2>/dev/null
   done
   ```
3. Chrome neu öffnen → `chrome://settings/performance` zeigt Memory Saver an

**Alternative** (alles in einem Bash-Skript):
```bash
#!/usr/bin/env bash
# scripts/chrome-prefs-quiet.sh — Memory Saver an, Energy Saver aus
CHROME_BASE="$HOME/Library/Application Support/Google/Chrome"
for prefs in "$CHROME_BASE/Default/Preferences" "$CHROME_BASE/Profile "*/Preferences ; do
  [ -f "$prefs" ] || continue
  /usr/bin/python3 <<<"
import json
p = '$prefs'
d = json.loads(open(p).read())
d.setdefault('performance', {})
d['performance'].setdefault('memory_saver_mode', {})['enabled'] = True
d['performance'].setdefault('energy_saver_mode', {})['enabled'] = False
open(p, 'w').write(json.dumps(d))
"
done
```

### 5.2 Firefox
```bash
rm -rf ~/Library/Caches/Mozilla
rm -rf ~/Library/Application Support/Firefox/Profiles/*/cache2
rm -rf ~/Library/Application Support/Firefox/Profiles/*/thumbnails
```
(Niemals `key4.db`, `logins.json`, `places.sqlite` — deine Passwörter + Bookmarks.)

### 5.3 Brave / Edge / Vivaldi / Arc / Opera
- Cache-Pfade analog Chrome, jeweils in `~/Library/Application Support/<Browser>/Default/{Cache,GPUCache,Code Cache,...}`
- Browser-Profile NICHT löschen
- `Brave-Browser/Caches/`, `PowerCache/`, `Service Worker/CacheStorage/`

---

## 6 · Developer-Caches (Klasse D)

Diese sind zu 100 % regenerierbar. **Hier kann der Agent autonom putzen ohne Confirm.**

### 6.1 Node / JS / Web-Toolchain

| Pfad | Größe (typisch) | Befehl |
|---|--:|---|
| `~/.npm` (root-owned files → sudo chown) | 1–10 GB | `sudo chown -R $USER ~/.npm && npm cache clean --force` |
| `~/Library/Caches/pnpm` | 200 MB–1 GB | `rm -rf` |
| `~/Library/Caches/yarn` | 100–500 MB | `rm -rf` |
| `~/Library/Caches/bun` | 50–300 MB | `rm -rf` |
| `~/Library/Caches/node-gyp` | 100 MB | `rm -rf` |
| `~/Library/Caches/electron` | 100 MB | `rm -rf` |
| `~/Library/Caches/next-swc` | 30 MB | `rm -rf` |

### 6.2 Python

| Pfad | Was |
|---|---|
| `~/Library/Caches/pip` (1 GB) | `rm -rf` |
| `~/.cache/pip` (Linux-style) | `rm -rf` (falls vorhanden) |
| `pip cache purge` | saubere Methode |
| `poetry cache clear --all` | bei Poetry-Nutzern |
| `~/.conda/pkgs` | conda-Paket-Cache (mehrere GB) |
| `~/.pyenv/cache` | pyenv-built cache |

### 6.3 Rust / Cargo

| Pfad | Was |
|---|---|
| `~/.cargo/registry/cache/` | gepurged via `cargo cache --autoclean` oder manuell |
| `~/.cargo/registry/src/` | Source-Cache |
| `~/.cargo/git/` | bare git clones (jeder ist ein Repo) |
| `~/.rustup/toolchains/<alte-version>` | `rustup toolchain uninstall <ver>` |
| `~/.rustup/tmp/` | partielle Builds |

> Aktive Default-Toolchain (`stable`) **NICHT** entfernen.

### 6.4 Go / Composer / PHP

| Pfad | Was |
|---|---|
| `~/Library/Caches/go-build` | best-effort: `go clean -cache` |
| `~/Library/Caches/composer` | Composer-Pakete |
| `~/.composer/cache` | (Linux-Pfad) |

### 6.5 TypeScript / LSP / Bundler

| Pfad | Was |
|---|---|
| `~/Library/Caches/typescript` | TS-Compiler-Cache |
| `~/Library/Caches/gopls` | Go-LSP |
| `~/Library/Caches/.lingma` | Antigravity AI |
| `~/Library/Caches/ms-playwright` | Playwright-Browser-Binaries (2,9 GB häufig!) |
| `~/Library/Caches/ms-playwright-go` | Playwright Go-Variante |

### 6.6 Java / JVM

| Pfad | Was |
|---|---|
| `~/.gradle/caches` | gradle cache |
| `~/.gradle/caches/transforms-*` | transform caches |
| `~/.m2/repository` | Maven repo (mehrere GB!) |
| `~/.ivy2/cache` | Ivy cache |
| `~/.sbt/0.13/streams` | SBT streams |

### 6.7 Xcode / iOS

| Pfad | Was |
|---|---|
| `~/Library/Developer/Xcode/DerivedData/` | 🟢 Build-Output, regenerierbar |
| `~/Library/Developer/Xcode/Archives/` | 🟠 App-Archive (signed builds) — nicht ohne Confirm |
| `~/Library/Developer/Xcode/iOS DeviceSupport/` | 🟢 iOS-Symbol-Server |
| `~/Library/Developer/CoreSimulator/Caches/` | 🟢 Sim-Cache |
| `~/Library/Developer/CoreSimulator/Devices/<alte>` | 🟠 ungenutzte Sim-Runtimes, `xcrun simctl delete unavailable` |

### 6.8 Homebrew & Formulas

```bash
brew cleanup -s --prune=all    # alter Cellar + Download-Cache (~700 MB)
brew autoremove                 # unused deps
rm -rf ~/Library/Caches/Homebrew
```
> Formulas NICHT entfernen ohne Confirm (das ist User-Code-Tooling).

### 6.9 Docker / Container

```bash
docker system prune -a --volumes    # ⚠️ löscht auch Container-Volumes!
docker image prune -a                # nur unreferenzierte Images
docker builder prune                 # Build-Cache
```

**Default: bei `power-user` und `developer-minimal` KEIN auto-prune** — VMs und Volumes können Daten enthalten. User muss explizit.

---

## 7 · Privacy-Daten — niemals ohne Backup / Confirm (Klasse E)

Diese Pfade sind **HEILIG**. Löschung = Datenverlust.

### 7.1 Persönlich (User-Datenbanken)

| Pfad | Was | Lösch-Strategie |
|---|---|---|
| `~/Library/Mail/` (2+ GB) | Apple-Mail-DB | ⚠️ niemals — Backup |
| `~/Library/Mail/V*/MailData/` | Mail-Indices | ⚠️ niemals |
| `~/Library/Messages/` | iMessage-Verlauf | ⚠️ niemals |
| `~/Library/Calendars/Calendar*` | Kalender-Sync-DB | ⚠️ niemals ohne Full-Backup |
| `~/Library/Reminders/Container` | Reminders DB | ⚠️ niemals |
| `~/Library/Notes/` (Notes DB) | Apple-Notes | ⚠️ offline-fähig → User-Daten |
| `~/Library/Group Containers/group.com.apple.notes` | Notes-Cache | 🟠 nur Cache-Pfad löschen |
| `~/Library/Group Containers/group.com.apple.freeform` | Freeform-Boards | ⚠️ niemals |
| `~/Library/Containers/com.apple.podcasts` | Podcast-DB | 🟠 meist OK nach Subs |
| `~/Library/Containers/com.apple.Safari/` | Browser-State | 🟠 nur Cache-Pfade (§5) |
| `~/Library/Photos Library.photoslibrary/` | Photo-Library | ⚠️ niemals via `rm`, User-Aktion in Photos.app |
| `~/Library/Mobile Documents/com~apple~CloudDocs/` | iCloud-Drive | ⚠️ niemals |
| `~/Library/Keychains/*.keychain*` | Passwörter/Certificates | ⚠️ NIEMALS löschen |

### 7.2 Browser-Logins

In jedem Browser-Profil (siehe §5) **niemals** diese Files löschen:
- `Login Data` / `Cookies` / `Local Storage` / `Session Storage` / `IndexedDB`
- `Bookmarks*`, `History`
- `Affiliation Database`, `Sync Data`

### 7.3 SSH / GPG

```bash
# NIEMALS ohne explizites User-OK:
~/.ssh/                # private keys
~/.gnupg/private-keys-v1.d/
~/.aws/credentials
~/.kube/config
~/.docker/config.json
```

### 7.4 Trash (.Trash)

**Vor dem Leeren Inhalt zeigen.** Trash kann private Fotos, PDFs, verschlüsselte Backups enthalten.

```bash
ls -la ~/.Trash/                # werfe einen Blick
# Anzeige der Files:
/usr/bin/find ~/.Trash -type f -exec stat "%n %s" {} +  | head -30
```

Wenn klar Müll (`.dmg`, `.pkg`, Logs, `node_modules/`-Bäume): `find ~/.Trash -depth -delete`.

Wenn private Files dabei (`.jpg`, `.heic`, `.mov`, `.pdf`, `.docx`): User fragen!

---

## 8 · Standard-Reinigungs-Wizard-Reihenfolge

Empfohlene Reihenfolge vom leichtesten zum schwersten Eingriff:

1. **Inventur** (lesen, nichts löschen)
2. **Dev-Caches** (§6, alle Profile) — autonom, kein Risiko
3. **Browser-Caches** (§5) — pro Profil cachelöschen, Logins bleiben
4. **Apple-Drittanbieter-App-Support** (§4) — pro App Bestätigung
5. **Apple-User-LaunchAgents** (§3.7) — pro Agent Bestätigung
6. **Apple Telemetrie + Analytics** (§3.4) — dev/sys-policy-toggle
7. **Spotlight aus** (`sudo mdutil -a -i off`)
8. **photoanalysisd aus** (sudo + Photos-Settings)
9. **Time Machine disable** (sudo)
10. **System-Daemons extra** (`/Library/LaunchDaemons`) — nur sudo
11. **Trash zeigen + leeren** (Bestätigung)
12. **Validation** (`df`, `top`, `launchctl list | wc -l`)
13. **Restart-Empfehlung** (`sudo shutdown -r +5` mit User-Bestätigung)

---

## 9 · Recovery / Restore-Befehle

| Aktion | Rückgängig |
|---|---|
| Spotlight aus | `sudo mdutil -a -i on` |
| TM aus | `sudo tmutil enable` |
| photoanalysisd aus | `sudo launchctl enable system/com.apple.photoanalysisd` |
| analyticsd aus | `sudo launchctl enable system/com.apple.analyticsd` |
| `~/Library/LaunchAgents/X.plist` weg | recreate oder `brew services` re-install |
| Browser-Cache weg | wird automatisch wieder gefüllt beim Surfen |
| Dev-Cache weg | `npm install` / `pnpm install` neu |
| Nikon-Cache weg | Camera-Connectivity-Lib neu |
| Apple-Snapshot weg → nicht wiederherstellbar | vorher immer `tmutil listlocalsnapshots /` checken |

> **Best Practice:** Vor großem Cleanup ein APFS-Snapshot machen:
> ```bash
> sudo tmutil snapshot /  # aber nicht wenn TM disabled
> ```
> Funktioniert nur, wenn Time Machine enabled ODER drei-Finger-Ctrl-Snapshot manuell.

---

## 10 · Safety-Rules (Agent-IMPERATIV)

1. **KEINE Löschung** vor User-Confirm, außer explizit „volle Kelle".
2. **KEINE Sudo-Befehle** ohne User-Passwort. Agent gibt Befehls-Block, User kopiert in Terminal.
3. **KEINE Privatordner** (`~/Documents`, `~/Desktop`, `~/Downloads`, `~/Pictures`, `~/Movies`, `~/Music`, Backup-Sticks).
4. **KEINE Schreibzugriffe** auf fremde `/Library/...` Pfade ohne Sudo.
5. **KEIN `defaults write`** gegen System-Settings ohne Erklärung.
6. **BEI UNSICHERHEIT** stoppen und User fragen.
7. **`set -euo pipefail`** in jedem Skript.
8. **PREVIEW PASS** vor Ausführung (`echo rm -rf …` als erstes + sleep 3 + User-OK).
9. **Niemals `~/.ssh/` oder `~/.gnupg/`** ohne explizite Erlaubnis.
10. **Bei Mail/Notes/Messages** immer zuerst User-Hinweis ausgeben: „Time Machine Snapshot empfohlen".

---

## 11 · Useful One-Liners

```bash
# Total diskbelegung pro Top-Verzeichnis
du -sh ~/* ~/Library/* 2>/dev/null | sort -h | tail -20

# Was sitzt im Cache?
du -sh ~/Library/Caches/* 2>/dev/null | sort -h | tail -15

# Was sitzt im Application Support?
du -sh ~/Library/Application\ Support/* 2>/dev/null | sort -h | tail -15

# Was läuft (top-RAM)?
ps aux | sort -nrk 4 | head -10

# Was wird heute / gestern modifiziert?
find ~ -mtime -2 -type f -size +50M 2>/dev/null | head -20

# Welche LaunchAgents starten automatisch?
ls -lt ~/Library/LaunchAgents/ | head

# Was sichert Time Machine heute?
tmutil status

# Welche APFS-Snapshots sind lokal?
tmutil listlocalsnapshots /

# RAM-Verbrauch pro App
vmmap --summary <PID> 2>/dev/null | head -20

# Top Disk-I/O
sudo iotop -C 5 2   # falls installiert; sonst `fs_usage`
```

---

## 12 · Referenzen & Quellen (Web Research 2026-07)

- Apple's Developer Documentation: launchd, SIP, APFS-Snapshots
- Howard Hinnant's `fs_usage` and `powermetrics` write-ups (Cpp-Channel 2024)
- EclecticLight.com — Howard Oakley auf macOS-internals, Spotlight-Architektur
- macops.ca — Sandboxing / TCC, gut für Privacy-Geschichten
- James Dempsey on launchd — Apple-interner Talk
- OpenSourceRepos (sqript/brew) — Community-Knowledge für Safe-Cache-Files
- man-Pages: `mdutil(8)`, `tmutil(8)`, `launchctl(1)`, `defaults(1)`, `du(1)`
- macOS 26.5.1 (Tag 25F80) Stand Juli 2026

> **Hinweis:** Stand-Wissen ist **macOS 26.5.1** (Build 25F80). Bei abweichenden Versionen vorher mit `sw_vers` und `defaults` lesen, ob Keys noch stimmen.

---

## 13 · Repository-Information

- **Repo:** <https://github.com/OpenSIN-Code/macos-cool>
- **Owner:** OpenSIN-Code (Org)
- **Lizenz:** MIT
- **Maintainer:** OpenSIN-Code community
- **Beitragen:** Issues mit Repro-Steps, PRs mit Repro + Vorher-Diagnose-Output
- **Cross-Skill-Use:** kann geladen werden via `~/.config/opencode/opencode.json`:
  ```json
  {
    "skills": {
      "paths": ["~/dev/macos-cool"]
    }
  }
  ```
  oder direkt:
  ```json
  {
    "skills": {
      "urls": ["https://raw.githubusercontent.com/OpenSIN-Code/macos-cool/main/SKILL.md"]
    }
  }
  ```

---

## 14 · Versions-Historie

- **v0.1** (2026-07-04) — Initial Cut, basierend auf OpenCode-Session beim User `Delqhi`. 47 Bloat-Categories, 4 Profile, 12 Scripts.
- TODO v0.2: mas-cli integration
- TODO v0.3: Valve Steam auto-prune
- TODO v0.4: Profile-Test-Suite
