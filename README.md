# ProximityLock

A macOS menu bar application that automatically locks your screen when your Apple Watch moves out of Bluetooth range.

## How It Works

ProximityLock passively monitors your Apple Watch's BLE signal strength. When the signal drops below a configurable threshold (you walk away), it waits a brief period and then locks the screen via `pmset displaysleepnow`. When you return, macOS Apple Auto Unlock handles the unlock.

```
Apple Watch BLE Signal
        │
        ▼
  CoreBluetooth Scanner (passive, allowDuplicates)
        │
        ▼
  Exponential Moving Average Filter (α=0.3)
        │
        ▼
  Hysteresis Evaluator (lock: -80 dBm / present: -55 dBm)
        │
        ▼
  State Machine (present → warning → away)
        │
        ▼
  pmset displaysleepnow
```

## Requirements

- macOS 14.0+
- Apple Silicon or Intel Mac
- Apple Watch (paired via Bluetooth)
- "Require password immediately after sleep" enabled in System Settings

## Installation

```bash
git clone https://github.com/backendeveloper/ProximityLock.git
cd ProximityLock
./Scripts/install.sh
```

This builds a release binary and creates an app bundle at `~/Applications/ProximityLock.app`.

To run:

```bash
open ~/Applications/ProximityLock.app
```

## Uninstallation

```bash
./Scripts/uninstall.sh
```

## Configuration

Configuration is stored at `~/.config/proximity-lock/config.json` and is created automatically on first launch.

| Parameter | Default | Description |
|---|---|---|
| `watchIdentifier` | `null` | UUID of selected Apple Watch (set via menu) |
| `watchName` | `null` | Display name of selected watch |
| `lockThreshold` | `-80` | RSSI below this triggers warning (dBm) |
| `presentThreshold` | `-55` | RSSI above this confirms presence (dBm) |
| `lockTimeout` | `12` | Seconds in warning state before locking |
| `signalLossTimeout` | `6` | Seconds without signal before locking |
| `emaAlpha` | `0.3` | EMA smoothing factor (0-1, higher = less smoothing) |
| `scanInterval` | `2.0` | BLE scan interval in seconds |
| `adaptiveScanInterval` | `1.0` | Faster scan interval during warning state |
| `enabled` | `true` | Master enable/disable toggle |
| `launchAtLogin` | `false` | Install LaunchAgent for auto-start |
| `lockOnBluetoothDisable` | `true` | Lock immediately if Bluetooth is turned off |

You can edit the file directly — the app watches for changes and reloads automatically.

## State Machine

```
UNKNOWN ──[rssi > present]──→ PRESENT
PRESENT ──[rssi < lock]─────→ WARNING (start lockTimer)
WARNING ──[rssi > present]──→ PRESENT (cancel timer)
WARNING ──[timeout expired]─→ AWAY (lock screen)
WARNING ──[signal lost]─────→ AWAY (lock screen)
ANY     ──[bluetooth off]───→ AWAY (immediate lock)
AWAY    ──[rssi > present]──→ PRESENT
```

## Architecture

Hexagonal (Ports & Adapters) architecture with zero external dependencies.

```
Presentation → Application → Domain ← Infrastructure
```

```
Sources/ProximityLock/
├── App/                     # Entry point, DI wiring
├── Domain/
│   ├── Models/              # ProximityState, SignalReading, WatchDevice, AppConfiguration
│   └── Ports/               # Protocol definitions (BluetoothScanning, ScreenLocking, etc.)
├── Infrastructure/
│   ├── Bluetooth/           # CoreBluetooth scanner, Apple Watch identification
│   ├── SignalProcessing/    # EMA filter, hysteresis evaluator
│   ├── Lock/                # pmset screen locker
│   ├── Configuration/       # JSON config store with file watching
│   └── LaunchAgent/         # launchd plist management
├── Application/             # State machine, proximity monitor orchestrator
├── Presentation/            # NSStatusItem menu bar UI
└── Utilities/               # Logger, ProcessRunner, Constants
```

## Menu Bar

The menu bar icon reflects the current state using SF Symbols:

| State | Icon | Description |
|---|---|---|
| Present | `antenna.radiowaves.left.and.right` | Watch is nearby |
| Warning | `antenna.radiowaves.left.and.right.slash` | Signal weak, timer running |
| Away | `lock.fill` | Screen locked |
| Unknown | `questionmark.circle` | Searching for watch |

## Security

- **Lock-only** — never unlocks (Apple Auto Unlock handles that)
- **No passwords stored** — uses `pmset displaysleepnow` + macOS password requirement
- **No network access** — zero HTTP calls
- **No private APIs** — only public frameworks (CoreBluetooth) and CLI tools (pmset)
- **Minimal permissions** — Bluetooth only, no Accessibility or Keychain access
- **Bluetooth-off fallback** — locks immediately if Bluetooth is disabled

## Testing

```bash
swift test
```

> **Note:** Requires Xcode (not just Command Line Tools) for XCTest framework.

### Log Monitoring

```bash
log stream --predicate 'subsystem == "com.proximity-lock"' --level debug
```

## License

MIT
