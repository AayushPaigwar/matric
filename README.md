# Matric (Pulse for Mac Clone)

> A high-performance, native macOS system monitor and activity companion built with **SwiftUI** and **AppKit**. Understand the apps, processes, developer runtimes, and performance spikes behind your day — 100% locally and privately.

---

## 📖 Overview & Mission

**Matric** is an open-source recreation and clone of [Pulse for Mac](https://pulsemac.app/). 

Unlike the stock macOS Activity Monitor — which presents an overwhelming, flat wall of disconnected UNIX threads and helper daemons — Matric brings system metrics, intelligent app grouping, developer workspace inspection, and 30-day historical time-travel into a clean, modern macOS interface.

### Key Tenets
1. **Clarity Over Clutter**: Child processes (renderers, workers, web content helpers) are automatically attributed to their parent application.
2. **Developer-First Context**: Real-time discovery of running development servers, working directories, and listening TCP ports.
3. **Local & Private by Design**: No telemetry, no background daemons, no cloud sync. All historical snapshots stay on your device in a local SQLite/SwiftData store.
4. **Adaptive Resource Efficiency**: Dynamic polling rates (2 seconds when visible, 10 seconds when minimized/hidden, 1-minute historical rollups) to ensure the monitor itself consumes negligible CPU and battery.

---

## 🎥 Screen-by-Screen Analysis (`pulse-demo-v1.mp4`)

Below is the exhaustive, screen-by-screen breakdown of the Pulse macOS application recorded in `pulse-demo-v1.mp4` (Duration: 79s, 1440×846 @ 30fps).

```
┌────────────────────────────────────────────────────────────────────────────────────────┐
│  Pulse Window Layout                                                                   │
├─────────────────────┬──────────────────────────────────────────────────────────────────┤
│ SIDEBAR             │ MAIN CONTENT VIEW                                                │
│                     │                                                                  │
│  RESOURCES          │  • Dynamic Header (Title, Subtitle, Status, Badges)              │
│   • Overview        │  • Summary KPI Cards Grid (Live Metrics & Trends)                │
│   • CPU             │  • Interactive Timeline Scrubbing Chart (1m / 5m / 10m)          │
│   • Memory          │  • Drill-down Tables / Tree Views (Apps, Disks, Ports, Folders)  │
│   • Disk            │                                                                  │
│   • Network         ├──────────────────────────────────────────────────────────────────┤
│   • Storage         │ STATUS FOOTER                                                    │
│   • Graphics        │  🔒 Local & Private  │  ● Live · 2s Refresh  │ Attribution Notes │
│   • Battery         │                                                                  │
│                     │                                                                  │
│  WORKSPACE          │                                                                  │
│   • Projects        │                                                                  │
│   • History         │                                                                  │
│   • Alerts          │                                                                  │
│   • Saved moments   │                                                                  │
│                     │                                                                  │
│  SYSTEM META        │                                                                  │
│   This Mac (M4,16GB)│                                                                  │
│   ● Live monitoring │                                                                  │
└─────────────────────┴──────────────────────────────────────────────────────────────────┘
```

---

### Screen 1: Overview Dashboard (`00:00 - 00:05`)
* **Sidebar**: Displays branding, search, grouped resource tabs (`RESOURCES` & `WORKSPACE`), and system spec badge (`Apple M4 · 10 cores · 16 GB RAM`).
* **KPI Metrics Grid** (6 primary cards):
  1. **CPU**: Overall utilization percentage (e.g. `50.5%`), split by `User %` and `System %`.
  2. **Memory**: Used RAM (e.g. `12.88 GB` of `16 GB`), memory pressure badge (`Normal`, `Elevated`, or `Compressed`).
  3. **Disk**: Free/Available disk space (e.g. `94.13 GB`), 1-minute read/write rates.
  4. **Network**: Total bandwidth (e.g. `5 KB/s download · 2 KB/s upload`).
  5. **Graphics**: GPU utilization percentage (e.g. `79.0% Apple M4`).
  6. **Battery**: Current battery charge (e.g. `54.0% On battery`).
* **Interactive Multi-Metric Timeline Chart**:
  - Time scale buttons: `1m`, `5m`, `10m`.
  - Area chart displaying dual metrics over time.
  - Hover tooltip with millisecond precision cursor scrubbing (`7:41:43 PM · CPU 27.9%`).
  - Stacked memory composition footer: `Active`, `Wired`, `Compressed`, and `Swap`.
* **Apps & Activity Table**:
  - Columns: App Icon + Name, Process Count, CPU %, Physical Footprint (RAM).
  - Search bar: *"Find an app"*.
  - Live sort by CPU load or memory usage.

---

### Screen 2: App Detail & Helper Process Inspector (`00:06 - 00:11`)
* **Trigger**: Clicking on any application row (e.g., `Google Chrome`, which owns 57 separate processes).
* **Inspector Sheet / Popover**:
  - **App Header**: App icon, name, total child process count, and live aggregated totals (`CPU: 136.3%`, `Physical footprint: 12.72 GB`).
  - **Child Processes List**:
    - Each sub-process listed with PID (e.g., `Google Chrome Helper (Renderer) PID 16,897`, `Google Chrome Helper PID 5,456`, `Google Chrome PID 5,452`).
    - Individual CPU % and physical memory footprint for every helper.
  - **Attribution Note**: Explains parent ancestry attribution vs registered bundle identifiers; highlights that shared OS daemons without a known owner remain distinct.
  - **Action Controls**:
    - `Show in Finder` (reveals app bundle)
    - `Quit app...` (graceful `SIGTERM` via `NSWorkspace` / `kill`)
    - `Force quit...` (`SIGKILL -9`)
    - `Done` (close modal)

---

### Screen 3: CPU Deep Dive (`00:12 - 00:15`)
* **Header & Summary KPIs**:
  - Total CPU percentage (e.g. `78.6%`)
  - User space usage (e.g. `49.8%`)
  - System/Kernel usage (e.g. `28.5%`)
  - Unix Load Average: `1-minute load: 5.72`
* **Timeline Chart**:
  - High-resolution CPU usage chart with 1m, 5m, and 10m historical views.
* **Process Table**:
  - Filtered by active CPU consumers, sorted dynamically by highest CPU percentage.

---

### Screen 4: Memory & Memory Pressure (`00:16 - 00:21`)
* **Header & KPIs**:
  - Current usage (`Now: 80.4%`)
  - Moving window average (`Sample average: 79.3%`)
  - Session peak (`Peak: 82.0%`)
  - Total working memory footprint (`12.93 GB`)
  - macOS Memory Pressure badge (`Elevated` / `Normal` / `Critical`)
  - Swap space allocated (`Swap: 14.56 GB`)
* **Memory Breakdown Bar**:
  - `Active` memory (e.g. `2.46 GB`)
  - `Wired` memory (un-pageable kernel RAM, e.g. `4.42 GB`)
  - `Compressed` memory (virtual memory compressed in RAM, e.g. `5.99 GB`)
  - `Swap` on disk (e.g. `14.56 GB`)
* **Interactive Chart & Table**:
  - Memory pressure trend over time.
  - App list sorted by physical memory footprint.

---

### Screen 5: Disk I/O & Storage Bandwidth (`00:22 - 00:27`)
* **Header & KPIs**:
  - Live Disk Read (`18.4 MB/s`) & Disk Write (`1.8 MB/s`)
  - Moving sample average and peak bandwidth (`Peak: 171.9 MB/s`)
* **Mounted Volumes Summary**:
  - APFS container name (`Macintosh HD`), free space (`94.12 GB available of 460.4 GB`).
  - Explanatory note: *"APFS volumes may share container capacity; their totals should not be added together."*
* **Real-time I/O Chart**:
  - Dual line graph: Read rate (solid line) vs Write rate (dashed line).
* **Per-App Disk Activity Table**:
  - Shows which apps are actively hitting the drive.
  - Columns: `APPLICATION`, `PROCESSES`, `READ / S`, `WRITE / S`.

---

### Screen 6: Network Interfaces & Throughput (`00:28 - 00:35`)
* **Header & KPIs**:
  - Real-time Download (`4 KB/s - 13 KB/s`) & Upload (`1 KB/s - 8 KB/s`)
  - Sample average & session peak (`1.9 MB/s`)
* **Network Chart**:
  - Visual throughput curves for inbound vs outbound packets.
* **Active Interfaces Table**:
  - Total active interfaces count (e.g., `22 active interfaces`).
  - Breakdown by interface identifier (e.g., `en0`, `en1`, `bridge0`, `anpi0`, `awdl0`, `ap1`).
  - Categorization: `Physical interface` vs `Virtual / tunnel interface`.
  - Real-time download and upload rate per interface.

---

### Screen 7: Graphics & GPU Utilization (`00:36 - 00:37`)
* **Header & KPIs**:
  - GPU load (`Now: 95.0%`, `Average: 69.5%`, `Peak: 96.0%`).
  - GPU Hardware Model: `Apple M4` (Apple Silicon unified GPU).
  - Driver-reported GPU memory allocation (`1.19 GB`).
  - Thermal State indicator (`Normal` / `Fair` / `Serious` / `Critical`).
* **GPU Utilization Chart**:
  - Historical timeline of GPU compute load.
* **Technical Note**:
  - *"Live device utilization reported by the graphics driver. GPU memory is a driver-reported figure, not additional physical RAM. Per-app GPU attribution is not available."*

---

### Screen 8: Battery Health & Power Draw (`00:38 - 00:41`)
* **Header & KPIs**:
  - Charge level (`53.0%`), moving average, and peak.
  - Power source: `Battery` vs `AC Power`.
  - Estimated time remaining: `1h 17m`.
* **Telemetry Details**:
  - State: `Discharging` / `Charging`
  - Battery Health / Maximum Capacity: `80.9%`
  - Cycle count: `668 cycles`
  - Internal Battery Temperature: `31.0 °C`
  - Real-time Power Draw: `35.8 W`
* **Peripheral Battery Section**:
  - Connected Bluetooth / HID device batteries (Magic Mouse, Magic Keyboard, AirPods, etc.).

---

### Screen 9: Storage Space Indexer & Visualizer (`00:42 - 00:49`)
* **Volume Usage Bar**:
  - `Macintosh HD`: `366.28 GB used · 94.13 GB free of 460.4 GB`.
* **Local Storage Index Controls**:
  - Scan state timestamp (`Last result 27 Sep 2026 at 7:42 PM`).
  - Buttons: `Choose folder...`, `Refresh`.
  - Total files measured: `301.03 GB`.
* **Category Grid (8 Storage Cards)**:
  1. `Downloads`: Size + status (`Up to date`)
  2. `Applications`: Size + status (`Up to date`)
  3. `Developer`: Size + status (`Partial access`)
  4. `Caches`: Size + status (`Update pending`)
  5. `Documents & Desktop`: Size + status (`Update pending`)
  6. `Media`: Size + status (`Up to date`)
  7. `App data`: Size + status (`Update pending`)
  8. `Other files`: Size + status (`Update pending`)
* **Permissions Banner**:
  - Detects unreadable files: *"419 items could not be read. For protected folders, enable Pulse in System Settings → Privacy & Security → Full Disk Access, then refresh."*
* **"Where your space goes" Explorer**:
  - Search field: *"Find a folder"*.
  - Ranked folder list with accurate recursive sizes:
    - `/System`, `/Users/.../Library/Application Support`, `/Users/.../Library/Developer`, `/Applications`, `/private`, `/Library/Caches`, developer project directories, container folders.

---

### Screen 10: Projects & Local Runtimes (`00:50 - 00:55`)
* **Header & Description**:
  - *"Local runtimes, grouped by their working folder."*
  - Sub-heading: *"Listening TCP ports · refreshes every 10 seconds"*
  - Option toggle: `[x] Include runtimes without ports`.
* **Project Cards**:
  - Automatically identifies development processes (`node`, `bun`, `python`, `redis-server`, `postgres`, `go`, etc.).
  - Resolves process working directory to a clean project name and path.
  - Card elements:
    - **Folder/Project Name**: e.g., `web`, `api`, `redis`
    - **File System Path**: e.g., `/Users/starc/Desktop/personal-projects/pulse/apps/web`
    - **Runtime & PID**: `node · PID 16,505`
    - **Listening TCP Ports**: e.g. `:4183`, `:49319, 49320`, `:6379`
    - **Live CPU % & Memory Usage**: e.g. `0.0% · 653.8 MB`
    - **Actions**:
      - `Reveal` (opens project folder in Finder / Terminal)
      - `Stop...` (gracefully stops or kills the server process)

---

### Screen 11: History & Time-Travel Scrubber (`00:56 - 01:05`)
* **Header**: *"Thirty days of measurements, stored on this Mac."*
* **Time Range Selector**: `12 hours` | `24 hours` | `7 days` | `30 days`.
* **Metric Selector**: Dropdown to inspect `CPU`, `Memory`, `Network`, `Disk`, etc.
* **Timeline Chart with Interactive Scrubber**:
  - Shows recorded samples (e.g. `217 displayed samples`).
  - User can drag or hover anywhere along the 30-day timeline.
  - Crosshair cursor displays the exact historical timestamp and metric value (e.g., `12:15:06 PM · CPU 27.8% · 27 Sep 2026`).
* **Time-Travel App State Inspection ("Apps at the selected time")**:
  - **Dynamic Snapshot Restoration**: The app table underneath reflects the **exact list of apps and their CPU/memory footprints at the scrubbed moment in time**.
  - Storage spec: 1 snapshot recorded every minute; automatically pruned after 30 days.

---

### Screen 12: Alerts & Sustained Load Monitoring (`01:06 - 01:11`, `01:18`)
* **Header**: *"Sustained activity that may need your attention."*
* **Configuration**: `Configure alerts` button to set thresholds.
* **Alert Feed ("This session")**:
  - Cards identifying background runway processes:
    - e.g., *"Google Chrome is using sustained CPU — Above 80% of one core for at least 120 seconds."*
    - Timestamp: `7:41 PM`.
    - Severity badge: `Normal` / `Warning` / `Critical`.

---

### Screen 13: Saved Moments (`01:12 - 01:13`)
* **Header**: *"A closer look at the moments you saved."*
* **Feature Concept**:
  - When the Mac feels laggy or a compile job spikes the system, press a hotkey or click "Save a moment".
  - Freezes a comprehensive diagnostic snapshot (top CPU apps, memory pressure, active window, battery draw, disk read/write).
  - Persistent post-mortem inspection list so developers can investigate without interrupting their flow.

---

### Screen 14: Settings Modal (`01:14 - 01:17`)
* **Modal Dialog ("Pulse Settings")**:
  1. **Updates**:
     - Current build version (e.g. `0.1.0 (1)`).
     - Checkbox: `Automatically check for updates`.
     - Button: `Check for Updates...` (Sparkle-compatible feed).
  2. **License**:
     - Status: `Development build` / `Licensed`.
     - Privacy commitment: *"Activation sends your license and a random installation ID. Your measurements are never uploaded."*
  3. **Monitoring**:
     - Sampling rate dropdown:
       - `While visible`: `Every 1 second` | `Every 2 seconds` | `Every 5 seconds`.
       - `While hidden`: `Every 10 seconds` | `Every 30 seconds` | `Paused`.
     - Checkbox: `Open Pulse at login` (`SMAppService.mainApp`).
  4. **Menu Bar Settings**:
     - `Metric`: Choose between `CPU`, `Memory`, `Network`, `Battery`, or `Storage`.
     - `Appearance`: Choose between `Figure` (numerical percentage/speed), `Icon`, or `Mini Graph`.

---

## 🛠 Feature Comparison & Requirements Matrix

| Feature Module | Pulse App Specification | Matric Implementation Plan |
| :--- | :--- | :--- |
| **App Hierarchy Attribution** | Group helper processes by parent PID and bundle identifier | `proc_pidinfo` + `NSRunningApplication` ancestry tree resolver |
| **CPU Monitoring** | Per-core and total CPU, User vs System %, Load Average | `host_processor_info`, `mach_host_self`, `getloadavg` |
| **Memory & Pressure** | Active, Wired, Compressed, Free, Swap, and Kernel Pressure Badge | `host_statistics64` (`vm_statistics64`), `sysctl` vm swap |
| **Disk Activity** | Live MB/s read and write throughput | `IOKit` (`IOBlockStorageDriver` statistics) |
| **Network Throughput** | Inbound/outbound bytes/s per interface + interface classifier | `sysctl` (`NET_RT_IFLIST2`), `getifaddrs` |
| **Apple Silicon GPU** | GPU load %, GPU driver memory, Thermal state | `IOReport` / `IOAccelerator` registry + `ProcessInfo.thermalState` |
| **Battery & Power** | Charge %, Wattage draw, Temperature, Health %, Cycle count | `IOPMPowerSource` + `IOPMrootDomain` via `IOKit` |
| **Storage Space Analyzer** | 8 categories + directory tree + Full Disk Access handling | Fast parallel `FileManager` directory scanner + APFS metadata |
| **Projects / Dev Runtimes** | Detect node, python, bun, docker, etc. with folder & listening ports | `libproc` (`PROC_PIDLISTFDS`, `PROC_PIDVNODEPATHINFO`) + `lsof`/socket query |
| **30-Day History** | 1-minute persistent snapshots with time-travel scrubber | Embedded SQLite / SwiftData with automatic 30-day sliding window |
| **Saved Moments** | Instant capture of system bottleneck state | On-demand frozen state serialization with notes |
| **Sustained Load Alerts** | Configurable CPU/Memory anomaly detector (>80% for >120s) | Sliding time-window threshold evaluator |
| **Menu Bar Companion** | Configurable metric display (Figure, Mini Graph, Icon) | `NSStatusItem` with custom SwiftUI popover |
| **Settings & Polling** | Dynamic 2s visible / 10s hidden polling rate, launch at login | `SMAppService`, SwiftUI Settings scene, adaptive `Combine` timer |

---

## 🏗 Architecture & Engineering Specs for Matric

```
matric/
├── App/
│   ├── MatricApp.swift               # Application entry point & Scene configuration
│   ├── MenuBarManager.swift          # NSStatusItem, status bar updates, menu popover
│   └── AppState.swift                # Central observable environment state
│
├── Core/
│   ├── SystemSensors/
│   │   ├── CPUMonitor.swift          # Mach host_processor_info, per-core & total load
│   │   ├── MemoryMonitor.swift       # vm_statistics64, memory pressure, swap usage
│   │   ├── DiskMonitor.swift         # IOKit disk I/O read/write throughput
│   │   ├── NetworkMonitor.swift      # getifaddrs / sysctl bandwidth per interface
│   │   ├── GPUMonitor.swift          # IOAccelerator / Apple Silicon GPU utilization
│   │   └── BatteryMonitor.swift      # IOPMPowerSource, cycle count, temperature, wattage
│   │
│   ├── ProcessEngine/
│   │   ├── ProcessScanner.swift      # libproc process enumeration
│   │   ├── ProcessTreeResolver.swift # Attributing helpers & daemons to parent apps
│   │   └── AppMetadataService.swift  # Icon extraction, bundle ID, display names
│   │
│   ├── ProjectDetector/
│   │   ├── PortScanner.swift         # Mapping listening TCP ports to PIDs
│   │   ├── WorkingDirResolver.swift  # Finding project directory for dev runtimes
│   │   └── DevRuntimeClassifier.swift# Node, Bun, Python, Ruby, Go, Redis, Docker, etc.
│   │
│   ├── StorageIndexer/
│   │   ├── VolumeManager.swift       # APFS container & volume information
│   │   ├── DiskSpaceScanner.swift    # Background parallel directory size calculator
│   │   └── FullDiskAccessHelper.swift# Permissions verification & system prompt
│   │
│   ├── History/
│   │   ├── HistoryDatabase.swift     # SQLite / SwiftData storage for 30-day snapshots
│   │   ├── SnapshotRecorder.swift    # 1-minute interval snapshot engine
│   │   └── TimeTravelPlayback.swift  # Historical snapshot interpolation & scrubber
│   │
│   └── AlertEngine/
│       ├── AlertRule.swift           # Threshold definitions (e.g. CPU > 80% for 120s)
│       └── AlertManager.swift        # Sustained load detection & session notifications
│
└── UI/
    ├── Navigation/
    │   ├── SidebarView.swift         # Sidebar navigation with Resources & Workspace groups
    │   └── WindowLayoutView.swift    # NavigationSplitView container
    │
    ├── Views/
    │   ├── Overview/                 # Overview dashboard with 6 KPI cards & timeline
    │   ├── CPU/                      # CPU deep-dive & per-core charts
    │   ├── Memory/                   # Memory composition & pressure views
    │   ├── Disk/                     # Disk I/O & per-app read/write activity
    │   ├── Network/                  # Interface list & network throughput
    │   ├── Graphics/                 # GPU compute activity & thermal state
    │   ├── Battery/                  # Battery health, power draw, peripheral levels
    │   ├── Storage/                  # Storage category cards & directory tree explorer
    │   ├── Projects/                 # Running developer servers, ports & kill actions
    │   ├── History/                  # Interactive 30-day time-travel scrubber
    │   ├── Alerts/                   # Sustained workload alerts list
    │   ├── SavedMoments/             # Bookmarked bottlenecks view
    │   └── Settings/                 # Preferences, refresh rates, menu bar customization
    │
    ├── Components/
    │   ├── MetricKPICard.swift       # Standard metric card component
    │   ├── TimelineChartView.swift   # Swift Charts live scrubbable area/line chart
    │   ├── ProcessInspectorSheet.swift# Modal for child processes & kill actions
    │   └── StatusFooterView.swift    # Bottom privacy & refresh rate bar
    │
    └── MenuBar/
        └── MenuBarPopoverView.swift  # Lightweight status bar popover view
```

---

## 💻 Native macOS System APIs Used

1. **Mach & Kernel APIs**:
   - `host_processor_info(mach_host_self(), PROCESSOR_CPU_LOAD_INFO, ...)` for per-core and aggregate CPU load.
   - `host_statistics64(mach_host_self(), HOST_VM_INFO64, ...)` for active, inactive, wired, and free memory pages.
   - `sysctl([CTL_VM, VM_SWAPUSAGE], ...)` for allocated and used swap memory.
2. **Process & App Identity**:
   - `proc_listpids(PROC_ALL_PIDS, ...)` and `proc_pidinfo(..., PROC_PIDTASKINFO)` for CPU and physical footprint.
   - `proc_pidinfo(..., PROC_PIDVNODEPATHINFO)` to get the process executable path and current working directory.
   - `NSRunningApplication` and `LSCopyApplicationURLsForBundleIdentifier` to link PIDs to parent applications and native icons.
3. **Network & Sockets**:
   - `sysctl([CTL_NET, PF_ROUTE, 0, 0, NET_RT_IFLIST2, 0])` for 64-bit hardware packet and byte counters per interface.
   - `PROC_PIDLISTFDS` and `proc_pidfdinfo` with `PROC_PIDFDSOCKETINFO` to identify open TCP sockets in `LISTEN` state and resolve port numbers.
4. **Disk I/O & Storage**:
   - `IOServiceGetMatchingServices(kIOMainPortDefault, IOServiceMatching("IOBlockStorageDriver"), ...)` to read total byte read/write statistics.
   - `URLResourceValues.totalFileAllocatedSizeKey` for accurate APFS allocated block sizing.
5. **GPU & Apple Silicon**:
   - `IOReport` API / `IOAccelerator` user client keys to read normalized GPU utilization without root privileges.
   - `ProcessInfo.processInfo.thermalState` for macOS thermal throttle levels.
6. **Power & Battery**:
   - `IOPMCopyPowerSourcesInfo()` and `IOPMCopyPowerSourcesList()` from `IOKit.ps`.
   - `IOPSGetPowerSourceDescription()` for instantaneous wattage draw, health percentage, temperature, and cycle count.

---

## 🚀 Getting Started with Matric

### Prerequisites
- macOS 14.0 (Sonoma) or macOS 15.0+ (Sequoia) / macOS 26+
- Xcode 15+ or 16+
- Swift 5.10 or Swift 6

### Opening in Xcode
```bash
open matric.xcodeproj
```

Build and run with `Cmd + R` in Xcode.

---

## 🔒 Privacy & Permissions
- **No Network Telemetry**: Matric makes zero outbound network requests.
- **Local Storage Only**: Snapshots are saved to `~/Library/Application Support/Matric/history.sqlite`.
- **Full Disk Access (Optional)**: Needed only by the **Storage Indexer** to calculate directory sizes inside protected directories (e.g. `~/Library/Application Support` or `/System`). All other features run within standard user privileges.

---

## 📄 License
MIT License. Inspired by [Pulse for Mac](https://pulsemac.app/).
