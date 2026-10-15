# Developer Projects Enhancement Roadmap & Feature Tracker

This document records the exact feature scope for the **Developer Projects & Ports** enhancements in Matric. Each feature is broken down into checklist tasks so we can develop, test, and verify them one by one.

---

## 📋 Feature Breakdown & Task Checklist

### Feature 1: Header & KPI Summary Metrics Bar
- [x] **1.1 Real-Time Metric Aggregation Engine**:
  - Compute `activeServicesCount`: count of active developer services and runtimes.
  - Compute `openPortsCount`: unique count of active TCP listening ports (`:3000`, `:5173`, `:8080`, etc.).
  - Compute `totalDevMemoryBytes`: aggregate RAM (RSS) consumed across all dev processes (e.g. `1.2 GB`).
  - Compute `totalDevCpuPercent`: combined CPU utilization across all dev processes with dynamic warning states (>20%).
- [x] **1.2 KPI Summary Bar UI Component**:
  - Build top-level 4-card KPI strip:
    - **Active Services**: `server.rack` icon, dynamic blue accent, scanning/online badges.
    - **Open TCP Ports**: `network` icon, purple accent, live open count badge.
    - **Dev Memory Usage**: `memorychip` icon, auto-formatted in `MB`/`GB` with High/Normal threshold tags.
    - **Dev CPU Load**: `cpu` icon, orange warning indicator when combined dev load >20%.

---

### Feature 2: Dual-View Mode: Rich Cards vs. High-Density Ports Table
- [x] **2.1 View Mode State & Toolbar Switcher**:
  - Add view switcher state (`Cards` / `Ports Table`) to `ProjectsView`.
  - Add segmented control in toolbar for fluid toggling with smooth transitions.
- [x] **2.2 High-Density Ports Table View**:
  - Dense tabular view with columns:
    - **Port**: Port number (e.g. `:3000`) in bold monospace with click-to-copy localhost URL shortcut.
    - **Status**: Network socket state (`LISTEN`) with colored indicator.
    - **Runtime / Service**: Framework branding icon and process command name.
    - **Project Path**: Truncated directory path with hover tooltip and 1-click copy shortcut.
    - **PID**: Monospaced process identifier.
    - **CPU %**: Real-time per-service CPU utilization with orange warning threshold.
    - **Memory**: Per-service RAM consumption.
    - **Direct Inline Actions**: 1-click **Open in Browser** (`arrow.up.forward.app`), **Copy URL** (`doc.on.doc`), **Terminal Launcher** (`terminal`), and **Kill Port** (`stop.fill`).
    - **Hover Lighting**: Interactive row hover feedback.
- [x] **2.3 Rich Cards View Polish**:
  - Card layout featuring framework branding, pulsing `ONLINE` status, quick IDE launchers (Cursor, VS Code, Terminal, Finder), copy URL/path shortcuts, and port badges.

---

### Feature 3: Smart Filtering & Organization
- [x] **3.1 Category Filter Pills**:
  - Quick toggle bar across:
    - **All**: All detected dev projects and services (`square.grid.2x2`).
    - **Web & APIs**: Next.js, Vite, React, Node, Bun, Deno, Python, FastAPI, Django, Flask, Go, Rust, Ruby (`globe`).
    - **Databases**: PostgreSQL (`5432`), Redis (`6379`), MongoDB (`27017`), MySQL (`3306`) (`cylinder.split.1x2`).
    - **Tunnels & Tooling**: VS Code Remote, T3 Code harness, Cloudflare Tunnels, SSH, Docker (`wrench.and.screwdriver`).
  - Real-time count badges embedded directly inside each category pill.
- [x] **3.2 Multi-Attribute Sorting**:
  - Sort projects uniformly across Cards and Ports Table by:
    - **Port Number** (numerical listening port order)
    - **CPU Usage** (highest CPU% first)
    - **Memory Footprint** (highest RAM bytes first)
    - **Project Name** (alphabetical A-Z)
  - Animated sort selection menu with active checkmarks.
- [x] **3.3 Live Search**:
  - Instant colon-agnostic search filtering across:
    - Project names
    - Port numbers (e.g. typing `:3000` or `3000`)
    - Git branches
    - File system paths
  - Live result counter (e.g. `X found`) and 1-click query clearing.
  - Contextual filter-aware empty state with a 1-click **"Reset Filters"** action button.

---

### Feature 4: Project Identity & Git Integration
- [x] **4.1 Zero-Subprocess Git Branch Detection**:
  - Automatically detect and display active git branch (e.g. `main`, `feature/auth`) by inspecting `.git/HEAD` upward without shelling out.
  - Full support for standard `.git` repos, Git worktrees (`gitdir:` pointer file), submodules, and detached HEAD commits.
  - Interactive 1-click copy git branch name shortcut across Cards and Ports Table with feedback toast.
- [x] **4.2 Status & Branding Badges**:
  - **Pulsing Status Pill**: Indicates `ONLINE` with a green radar pulse dot when server is actively listening on TCP ports, and `IDLE` when quiet.
  - **Pulsing Socket Dot**: Real-time pulsing socket dot for `LISTEN` rows in the high-density table.
  - **Framework Logos & Badges**: Distinct color-coded badge and iconic glyph for Vite, Next.js, React, Node, Bun, Python, FastAPI, Django, Flask, Go, Rust, Ruby, Docker, PostgreSQL, Redis, MongoDB, MySQL, and Tunnel tooling.

---

### Feature 5: 1-Click Developer Actions
- [x] **5.1 Direct IDE Launchers**:
  - **Cursor**: Opens project directory directly in Cursor (`com.todesktop.230313mzl4w4u92`, `com.cursor.Cursor`, or `/Applications/Cursor.app` with CLI fallback).
  - **VS Code**: Opens project directory directly in Visual Studio Code (`com.microsoft.VSCode`, Insiders, or `/Applications/Visual Studio Code.app` with CLI fallback).
  - **Terminal**: Opens Terminal tab cd'd to the project path with activated window focus.
  - **Finder**: Reveals project directory directly in macOS Finder with item selection.
  - Available across both Cards View and Ports Table View (dedicated action buttons + right-click context menu).
- [x] **5.2 Port Actions & Clipboard Helpers**:
  - `http://localhost:<PORT>` 1-click launch in macOS default web browser.
  - 1-click copy localhost URL (`doc.on.doc`) with floating feedback toast.
  - 1-click copy project directory path.
  - 1-click copy active Git branch name.
  - Full right-click `.contextMenu` on both Project Cards and Ports Table rows.

---

### Feature 6: Built-in Port Inspector Utility
- [ ] **6.1 Port Conflict Watchdog Sheet**:
  - Added a **"Check Port..."** utility sheet in the header.
  - Enter any port (e.g. `3000`, `8080`, `5432`) to check if it is free or in use.
- [ ] **6.2 Conflict Details & 1-Click Kill**:
  - If occupied, shows process name, PID, user, CPU%, and memory.
  - 1-click **"Kill Process"** button to free the port immediately.

---

## 🛠️ Step-by-Step Development Order
- [x] **Step 1**: Implement Feature 1 (Header & KPI Summary Metrics Bar)
- [x] **Step 2**: Implement Feature 2 (Dual-View Mode: Rich Cards vs. Ports Table)
- [x] **Step 3**: Implement Feature 3 (Smart Filtering & Organization)
- [x] **Step 4**: Implement Feature 4 (Project Identity & Git Integration)
- [x] **Step 5**: Implement Feature 5 (1-Click Developer Actions)
- [ ] **Step 6**: Implement Feature 6 (Built-in Port Inspector Utility)
