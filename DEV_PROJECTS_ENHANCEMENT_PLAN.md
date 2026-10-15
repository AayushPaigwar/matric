# Developer Projects Enhancement Roadmap & Feature Tracker

This document records the exact feature scope for the **Developer Projects & Ports** enhancements in Matric. Each feature is broken down into checklist tasks so we can develop, test, and verify them one by one.

---

## 📋 Feature Breakdown & Task Checklist

### Feature 1: Header & KPI Summary Metrics Bar
- [ ] **1.1 Real-Time Metric Aggregation Engine**:
  - Compute `activeServicesCount`: count of active developer services and runtimes.
  - Compute `openPortsCount`: unique count of active TCP listening ports (`:3000`, `:5173`, `:8080`, etc.).
  - Compute `totalDevMemoryBytes`: aggregate RAM (RSS) consumed across all dev processes (e.g. `1.2 GB`).
  - Compute `totalDevCpuPercent`: combined CPU utilization across all dev processes with dynamic warning states (>20%).
- [ ] **1.2 KPI Summary Bar UI Component**:
  - Build top-level 4-card KPI strip:
    - **Active Services**: `server.rack` icon, dynamic blue accent.
    - **Open TCP Ports**: `network` icon, purple accent.
    - **Dev Memory Usage**: `memorychip` icon, auto-formatted in `MB`/`GB`.
    - **Dev CPU Load**: `cpu` icon, orange warning indicator when load >20%.

---

### Feature 2: Dual-View Mode: Rich Cards vs. High-Density Ports Table
- [ ] **2.1 View Mode State & Toolbar Switcher**:
  - Add view switcher state (`Cards` / `Ports Table`) to `ProjectsView`.
  - Add segmented control in toolbar for fluid toggling.
- [ ] **2.2 High-Density Ports Table View**:
  - Dense tabular view with columns:
    - **Port**: Port number (e.g. `:3000`) in bold monospace.
    - **Status**: Network socket state (`LISTEN`) with colored indicator.
    - **Runtime / Service**: Framework branding icon and process command name.
    - **Project Path**: Truncated directory path with hover tooltip and copy shortcut.
    - **PID**: Monospaced process identifier.
    - **CPU %**: Real-time per-service CPU utilization.
    - **Memory**: Per-service RAM consumption.
    - **Direct Inline Actions**: 1-click **Open in Browser** (`safari`) and **Kill Port** (`xmark.circle`).
- [ ] **2.3 Rich Cards View Polish**:
  - Card layout featuring framework branding, live status, quick IDE launchers, and port badges.

---

### Feature 3: Smart Filtering & Organization
- [ ] **3.1 Category Filter Pills**:
  - Quick toggle bar across:
    - **All**: All detected dev projects and services.
    - **Web & APIs**: Next.js, Vite, React, Node, Bun, Deno, Python, FastAPI, Django, Flask, Go, Rust, Ruby.
    - **Databases**: PostgreSQL (`5432`), Redis (`6379`), MongoDB (`27017`), MySQL (`3306`).
    - **Tunnels & Tooling**: VS Code Remote, T3 Code harness, Cloudflare Tunnels, SSH, Docker.
- [ ] **3.2 Multi-Attribute Sorting**:
  - Sort projects by: **Port Number**, **CPU Usage**, **Memory Footprint**, or **Project Name**.
- [ ] **3.3 Live Search**:
  - Instant search filtering by project name, port (`:3000`), git branch, or file path.

---

### Feature 4: Project Identity & Git Integration
- [ ] **4.1 Zero-Subprocess Git Branch Detection**:
  - Automatically detect and display active git branch (e.g. `main`, `feature/auth`) by inspecting `.git/HEAD` upward without shelling out.
- [ ] **4.2 Status & Branding Badges**:
  - **Pulsing Status Pill**: Indicates `ONLINE` with a green pulse dot when server is actively listening on TCP ports.
  - **Framework Logos & Badges**: Distinct color-coded badge for Vite, Next.js, React, Node, Bun, Python, FastAPI, Django, Go, Rust, Ruby, Docker, and Database services.

---

### Feature 5: 1-Click Developer Actions
- [ ] **5.1 Direct IDE Launchers**:
  - **Cursor**: Opens project directory directly in Cursor (`com.todesktop.230313mzl4w4u92`).
  - **VS Code**: Opens project directory directly in Visual Studio Code (`com.microsoft.VSCode`).
  - **Terminal**: Opens Terminal tab cd'd to the project path.
  - **Finder**: Reveals project in macOS Finder.
- [ ] **5.2 Port Actions & Clipboard Helpers**:
  - `http://localhost:<PORT>` button to open in default browser.
  - Copy URL (`doc.on.doc`) with animated toast feedback.
  - Copy directory path with 1-click.

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
- [ ] **Step 1**: Implement Feature 1 (Header & KPI Summary Metrics Bar)
- [ ] **Step 2**: Implement Feature 2 (Dual-View Mode: Rich Cards vs. Ports Table)
- [ ] **Step 3**: Implement Feature 3 (Smart Filtering & Organization)
- [ ] **Step 4**: Implement Feature 4 (Project Identity & Git Integration)
- [ ] **Step 5**: Implement Feature 5 (1-Click Developer Actions)
- [ ] **Step 6**: Implement Feature 6 (Built-in Port Inspector Utility)
