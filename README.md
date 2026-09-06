<div align="center">

# 🔔 SheepBell

**A tiny macOS menu bar bell for your [herdr](https://herdr.dev) coding agents.**

Glance at the menu bar to see which agents are working, which are done,
and which are blocked waiting for *you* — then jump straight to the pane
with one click.

![macOS 15+](https://img.shields.io/badge/macOS-15%2B-blue?logo=apple)
![Swift 6](https://img.shields.io/badge/Swift-6.0-orange?logo=swift)
![License: Apache-2.0](https://img.shields.io/badge/License-Apache--2.0-blue)

</div>

---

## 🔔 Install it, and just look up

**There is nothing to configure.** Drop SheepBell in your Applications
folder, launch it, and it silently finds every **running herdr server** on
your machine — along with all of its **sessions, workspaces, and agents** —
all by itself. No setup files, no CLI wiring, no paths to paste.

From that moment on, the menu bar icon *is* your status dashboard:

- 🔴 **Octagon** — an agent is blocked and waiting on **you**
- 🔵 **Spinning arrows** — agents are working
- 🟢 **Checkmark** — work finished, waiting to be reviewed
- ⚪️ **Grid** — everyone is idle
- 🚫 **Slashed circle** — no herdr running right now

One glance tells you whether it's safe to make coffee. One click opens the
full per-session agent list; one more click jumps straight to that agent's
pane. That's the whole product.

## ✨ What it does

- **Live agent status in your menu bar** — every agent running in herdr,
  grouped by session, with a status icon per agent.
- **One aggregate icon** — the menu bar symbol reflects the most urgent
  status across all connected sessions, so a single glance is enough.
- **Click to focus** — selecting an agent tells herdr to focus its pane
  (`agent.focus`). No window hunting.
- **Notifications that matter** — a macOS notification fires the moment an
  agent becomes **blocked** (needs your approval/answer) or **done**
  (finished background work).
- **Zero CLI dependency** — talks directly to herdr's Unix-domain socket
  protocol (newline-delimited JSON): snapshot bootstrap, then a live event
  subscription. No polling, no shell, no PATH issues.
- **Multi-session** — automatically discovers the default session and every
  named session (`~/.config/herdr/sessions/*/herdr.sock`), with file-system
  watching, ping-based liveness checks, and exponential-backoff reconnects.
- **8 languages** — English (default), 한국어, 简体中文, Tiếng Việt, Deutsch,
  हिन्दी, Français, 日本語. Switch live from the Configure window, no relaunch.
- **Pluggable icon schemes** — status icons come from a swappable theme
  engine; new schemes can be added without touching the UI code.

## 🚀 Install

### Requirements

- macOS 15 or later
- A running [herdr](https://herdr.dev) server — SheepBell finds it automatically,
  together with every session, workspace, and agent inside it. Nothing else.

> **Windows and Linux versions will launch later.** SheepBell is macOS-only
> for now; cross-platform builds are on the roadmap.

### Download & install (recommended)

Grab the latest `SheepBell.zip` from the
[Releases page](https://github.com/bonanyan/sheepbell/releases), unzip it,
and drag `SheepBell.app` into `/Applications`. Launch it — that's the whole
install. It appears in the menu bar and immediately starts watching herdr:
no config files, no terminal commands, no setup wizard.

> Release downloads are coming soon; until then, build from source below.

### Build from source (XcodeGen required)

[XcodeGen](https://github.com/yonaskolb/XcodeGen) is needed **only for
building from source** — an installed release needs nothing but macOS and
herdr.

```sh
xcodegen generate
open SheepBell.xcodeproj   # then ⌘R, or:
xcodebuild -project SheepBell.xcodeproj -scheme SheepBell -configuration Release build
```

Or use the packaging script, which produces a signed, zipped app:

```sh
Scripts/package.sh          # → build/SheepBell.app + build/SheepBell.zip
```

SheepBell runs as a menu-bar-only app (`LSUIElement`) — no Dock icon,
no main window. On first launch it asks for permission to send
notifications. Flip on **Launch SheepBell at login** in Configure and it
will be watching your agents from the first second of every session.

## 📖 Reading the icons

### Agent statuses (menu rows)

| Status | Meaning | Icon (Classic scheme) | Color |
|---|---|---|---|
| `blocked` | herdr detected an approval prompt or a question — **the agent needs you** | `hand.raised.fill` | 🔴 Red |
| `working` | The agent is actively running | `arrow.triangle.2.circlepath` | 🔵 Blue |
| `done` | Background work finished; the tab hasn't been viewed yet | `checkmark.circle.fill` | 🟢 Green |
| `idle` | Ready for input (already viewed) | `circle.fill` | ⚪️ Gray |
| `unknown` | An agent is present but can't be classified reliably | `questionmark.circle` | ⚪️ Gray |

A small `cursorarrow.rays` marker shows which agent currently has focus
in herdr.

### Menu bar aggregate symbol

The single menu bar icon summarizes **all** connected sessions using a
strict priority: **blocked > working > done > idle**.

| Menu bar icon | State |
|---|---|
| `exclamationmark.octagon.fill` | At least one agent is **blocked** |
| `arrow.triangle.2.circlepath` | At least one agent is **working** (none blocked) |
| `checkmark.circle.fill` | At least one agent is **done** (none blocked/working) |
| `circle.grid.2x2` | Everything is **idle** |
| `circle.slash` | **No herdr session connected** (server down or not found) |

**Idle debounce:** transitions *to* the all-idle grid are delayed by 5
seconds. Agents flicker through `idle` between tool calls; the debounce
keeps the menu bar stable while work is clearly still in progress.
Transitions to blocked/working/done and disconnects are **immediate**.

## ⚙️ Configure

Click the menu bar icon → **Configure…** to open the settings window:

| Setting | Options |
|---|---|
| **Language** | English (default), Korean, Chinese (Simplified), Vietnamese, German, Hindi, French, Japanese — applied instantly to menus, settings, and notifications |
| **Icon style** | The icon scheme used for agent statuses and the menu bar symbol (currently **Classic**; more schemes can be added) |
| **Launch SheepBell at login** | Registers the app as a login item via `SMAppService` |
| **Notify when an agent becomes blocked or done** | Master switch for macOS notifications |

## 🏗 Architecture

```
herdr server ──unix socket──► HerdrSocket (NWConnection actor)
                                   │
              SessionDiscovery ──► HerdrSessionClient (per session)
              (glob + FSEvents)    ping → session.snapshot → events.subscribe
                                   │
                                   ▼
                             HerdrStore (@Observable, main actor)
                                   │  aggregate icon + debounce (IconScheme)
              ┌────────────────────┼────────────────────┐
              ▼                    ▼                    ▼
          MenuView             Notifier           SettingsView
     (MenuBarExtra window)  (blocked/done)      (Configure window)
```

```
Sources/
├── App/SheepBellApp.swift           @main, MenuBarExtra + Settings scenes
├── Core/
│   ├── HerdrWire.swift              Codable envelopes for the herdr protocol
│   ├── HerdrSocket.swift            NWConnection(.unix) actor: one-shot + streaming
│   ├── HerdrSessionClient.swift     per-session state machine, reconnect w/ backoff
│   ├── SessionDiscovery.swift       finds & watches all herdr sockets
│   ├── AgentItem.swift              view-model for one agent row
│   └── HerdrStore.swift             main-actor aggregate store driving the UI
├── Features/
│   ├── Menu/MenuView.swift          session groups → agent rows → focus on click
│   ├── SettingsView.swift           Configure window (language / icons / login / notify)
│   ├── Localization.swift           AppLanguage + LocalizationManager (live switching)
│   ├── IconSchemes/
│   │   ├── IconScheme.swift         the theme protocol
│   │   ├── ClassicIconScheme.swift  the built-in scheme
│   │   └── IconSchemeRegistry.swift discovery + persistence keys
│   ├── LoginItem.swift              SMAppService wrapper
│   └── Notifier.swift               UNUserNotificationCenter posting
└── Resources/Localizable.xcstrings  String Catalog (8 languages)
```

### Adding an icon scheme

1. Create a struct conforming to `IconScheme` (see `ClassicIconScheme`).
2. Append it to `IconSchemeRegistry.all`.
3. Add a localized display name under its `displayNameKey` in the String Catalog.

That's it — the Configure picker, the menu, and the menu bar aggregate all
pick up the new scheme automatically.

## 🧪 Tests

```sh
xcodebuild -project SheepBell.xcodeproj -scheme SheepBell test
```

swift-testing suite covering wire decoding (recorded JSON fixtures),
aggregate-icon priority & debounce, notification policy, icon scheme
registry, plus live-socket integration tests that run against a real
herdr server when one is available.

## 🙏 Acknowledgments

Built on the excellent [herdr](https://herdr.dev) terminal multiplexer for
coding agents and its documented socket API.

## 📄 License

Apache License Version 2.0 — see [LICENSE](LICENSE).
