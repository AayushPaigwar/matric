# Developer Projects UI & UX Enhancement Plan

Comprehensive, phased blueprint to elevate the **Developer Projects** experience in **Matric** into a high-performance, developer-first command center for discovering local servers, diagnosing port conflicts, monitoring resources, and launching dev tools.

---

## 🚀 Scope of Enhancements

### Feature 1: Header & KPI Summary Metrics Bar
- [x] **1.1 Real-Time Metric Aggregation Engine**:
  - **Active Services**: Count of active developer services and runtimes.
  - **Open TCP Ports**: Count of unique active listening ports (`:3000`, `:5173`, `:8080`, etc.).
  - **Dev Memory Usage**: Aggregate RAM consumed by all running dev processes (e.g. `1.2 GB`).
  - **Dev CPU Load**: Combined CPU utilization with dynamic warning colors when >20%.
- [x] **1.2 Visual KPI Bar**:
  - Sleek top row of 4 translucent, rounded cards with accent badges and iconography.
  - Live background telemetry updates from `SystemTelemetryHub` every 1 second without full disk re-scans.

---

### Feature 2: Dual-View Mode: Rich Cards vs. High-Density Ports Table
- [x] **2.1 View Switcher Control**:
  - Segmented control in the toolbar to toggle between **Cards View** (`square.grid.2x2`) and **Ports Table** (`tablecells`).
- [x] **2.2 High-Density Ports Table**:
  - Columnar layout displaying:
    - **Port**: `:3000`, `:5173` with click-to-copy URL shortcut.
    - **Status**: Live socket state (`LISTEN` with pulsing green dot).
    - **Service / Runtime**: Framework badge with icon (e.g. Node, Next.js, Vite, Python, Go, Rust).
    - **Project / Path**: Directory name with click-to-copy path and branch indicator.
    - **PID**: Process identifier.
    - **Resource**: Real-time CPU% and Memory usage.
    - **Actions**: Direct inline buttons: Open in Browser, Copy URL, Cursor/VS Code launch, Terminal, Finder, and Stop/Kill Port.
- [x] **2.3 Redesigned Cards View**:
  - Preserves rich metadata, process paths, memory/CPU badges, and port links in an airy card layout.

---

### Feature 3: Smart Filtering & Organization
- [x] **3.1 Category Filter Bar**:
  - Horizontal filter pills with live counter badges:
    - **All** (`tray.2`)
    - **Web / Frontend** (`globe`)
    - **Backend & APIs** (`server.rack`)
    - **Databases** (`cylinder`)
    - **Tunnels & Tools** (`arrow.left.arrow.right`)
- [x] **3.2 Multi-Attribute Sorting**:
  - Dropdown sort menu supporting:
    - **Port Number (Ascending)** (default for easy port discovery)
    - **CPU Utilization (Descending)**
    - **Memory Usage (Descending)**
    - **Project Name (A-Z)**
- [x] **3.3 Colon-Agnostic Port & Project Search**:
  - Search input queries across Project name, directory path, framework, and port number (supports searching either `:3000` or `3000`).
  - Result count indicators and 1-click query clearing.
  - "Reset Filters" action button when zero results match.

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
- [x] **6.1 Port Conflict Watchdog Sheet**:
  - Dedicated **"Check Port..."** utility sheet in the header.
  - Enter any port (e.g. `3000`, `8080`, `5432`) to check if it is free or in use.
  - Quick preset buttons for common dev ports (`:3000`, `:5173`, `:8080`, `:8000`, `:5432`, `:6379`, `:27017`, `:3306`).
- [x] **6.2 Conflict Details & 1-Click Kill**:
  - If occupied, shows process name, PID, user, CPU%, memory, and directory path.
  - 1-click **"Open in Browser"** and **"Copy URL"** actions.
  - 1-click **"Release Port"** (graceful `SIGTERM`) and **"Force Kill"** (`SIGKILL`) to free the port immediately with live status updating to `.free(port)`.

---

## 🛠️ Step-by-Step Development Order
- [x] **Step 1**: Implement Feature 1 (Header & KPI Summary Metrics Bar)
- [x] **Step 2**: Implement Feature 2 (Dual-View Mode: Rich Cards vs. Ports Table)
- [x] **Step 3**: Implement Feature 3 (Smart Filtering & Organization)
- [x] **Step 4**: Implement Feature 4 (Project Identity & Git Integration)
- [x] **Step 5**: Implement Feature 5 (1-Click Developer Actions)
- [x] **Step 6**: Implement Feature 6 (Built-in Port Inspector Utility)
