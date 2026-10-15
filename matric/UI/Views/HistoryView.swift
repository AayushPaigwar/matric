import SwiftUI
import Charts

public struct HistoryView: View {
    @Environment(AppState.self) private var appState
    @Environment(SystemTelemetryHub.self) private var hub
    private var historyStore = HistoryStore.shared
    
    @State private var hoveredPoint: HistoryPoint? = nil
    @State private var showingClearConfirmation: Bool = false
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
            
            Divider()
            
            // Content
            ScrollView {
                VStack(spacing: 20) {
                    // Time Range & Metric Selectors
                    controlToolbar
                    
                    // Main History Chart Card
                    chartCard
                    
                    // Statistical Summary Row
                    statisticsGrid
                    
                    // Activity Highlights Section
                    highlightsSection
                }
                .padding(.horizontal, 28)
                .padding(.vertical, 24)
            }
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .alert("Clear Historical Telemetry?", isPresented: $showingClearConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Clear All", role: .destructive) {
                historyStore.clearHistory()
            }
        } message: {
            Text("This will permanently remove all stored sensor measurements on this Mac.")
        }
    }
    
    // MARK: - Header
    private var headerView: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 8) {
                    Text("History")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(.primary)
                    
                    Text("\(historyStore.points.count) data points")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2.5)
                        .background(
                            Capsule().fill(Color.primary.opacity(0.06))
                        )
                }
                
                Text("Long-term hardware measurements and performance trends stored on this Mac.")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            HStack(spacing: 10) {
                Button {
                    showingClearConfirmation = true
                } label: {
                    Label("Clear Data", systemImage: "trash")
                        .font(.system(size: 12))
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 18)
    }
    
    // MARK: - Control Toolbar (Range & Metric)
    private var controlToolbar: some View {
        HStack {
            // Metric selector pills
            HStack(spacing: 6) {
                ForEach(HistoryMetricType.allCases) { metric in
                    Button {
                        historyStore.selectedMetric = metric
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: metric.iconName)
                                .font(.system(size: 11))
                            Text(metric.rawValue)
                                .font(.system(size: 12, weight: historyStore.selectedMetric == metric ? .semibold : .regular))
                        }
                        .padding(.horizontal, 11)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(historyStore.selectedMetric == metric ? metric.chartColor.opacity(0.2) : Color.clear)
                        )
                        .foregroundStyle(historyStore.selectedMetric == metric ? metric.chartColor : .secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(3)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color(nsColor: .controlBackgroundColor).opacity(0.6))
            )
            
            Spacer()
            
            // Time range selector
            HStack(spacing: 3) {
                ForEach(HistoryRange.allCases) { range in
                    Button {
                        historyStore.selectedRange = range
                    } label: {
                        Text(range.shortLabel)
                            .font(.system(size: 11, weight: historyStore.selectedRange == range ? .bold : .medium))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(
                                Capsule().fill(historyStore.selectedRange == range ? Color.accentColor : Color.clear)
                            )
                            .foregroundStyle(historyStore.selectedRange == range ? .white : .secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(3)
            .background(
                Capsule().fill(Color(nsColor: .controlBackgroundColor).opacity(0.8))
            )
        }
    }
    
    // MARK: - Big Interactive Chart Card
    private var chartCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Chart Header info
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(historyStore.selectedMetric.chartColor)
                            .frame(width: 8, height: 8)
                        
                        Text(historyStore.selectedMetric.rawValue)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.primary)
                        
                        Text("• \(historyStore.selectedRange.rawValue)")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }
                    
                    if let pt = hoveredPoint {
                        Text(String(format: "Scrub: %.1f %@ at %@", pt.value(for: historyStore.selectedMetric), historyStore.selectedMetric.unitLabel, pt.timestamp.formatted(date: .omitted, time: .shortened)))
                            .font(.system(size: 12, weight: .semibold, design: .monospaced))
                            .foregroundStyle(historyStore.selectedMetric.chartColor)
                    } else {
                        Text("Hover across graph to scrub timeline measurements")
                            .font(.system(size: 11))
                            .foregroundStyle(.tertiary)
                    }
                }
                
                Spacer()
                
                // Peak Badge
                HStack(spacing: 5) {
                    Text("PEAK")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.secondary)
                    Text(String(format: "%.1f %@", historyStore.peakValue, historyStore.selectedMetric.unitLabel))
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(RoundedRectangle(cornerRadius: 6).fill(Color.primary.opacity(0.05)))
            }
            
            // SwiftUI Chart
            let points = historyStore.currentRangePoints
            let color = historyStore.selectedMetric.chartColor
            
            Chart {
                ForEach(points) { pt in
                    AreaMark(
                        x: .value("Time", pt.timestamp),
                        y: .value(historyStore.selectedMetric.rawValue, pt.value(for: historyStore.selectedMetric))
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [color.opacity(0.35), color.opacity(0.02)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    
                    LineMark(
                        x: .value("Time", pt.timestamp),
                        y: .value(historyStore.selectedMetric.rawValue, pt.value(for: historyStore.selectedMetric))
                    )
                    .foregroundStyle(color)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                }
                
                // Average benchmark rule
                RuleMark(y: .value("Average", historyStore.averageValue))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    .foregroundStyle(Color.secondary.opacity(0.4))
                
                // Cursor Rule on Scrub
                if let hovered = hoveredPoint {
                    RuleMark(x: .value("Selected", hovered.timestamp))
                        .lineStyle(StrokeStyle(lineWidth: 1))
                        .foregroundStyle(Color.primary.opacity(0.6))
                    
                    PointMark(
                        x: .value("Time", hovered.timestamp),
                        y: .value(historyStore.selectedMetric.rawValue, hovered.value(for: historyStore.selectedMetric))
                    )
                    .foregroundStyle(color)
                    .symbolSize(40)
                }
            }
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 6)) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(Color.primary.opacity(0.06))
                    AxisValueLabel(format: .dateTime.hour().minute())
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
            }
            .chartYAxis {
                AxisMarks(position: .trailing, values: .automatic(desiredCount: 5)) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(Color.primary.opacity(0.06))
                    AxisValueLabel {
                        if let d = value.as(Double.self) {
                            Text(String(format: "%.0f %@", d, historyStore.selectedMetric.unitLabel))
                                .font(.system(size: 9))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .chartOverlay { proxy in
                GeometryReader { geometry in
                    Rectangle()
                        .fill(Color.clear)
                        .contentShape(Rectangle())
                        .onContinuousHover { phase in
                            switch phase {
                            case .active(let location):
                                guard let plotFrame = proxy.plotFrame else { return }
                                let xPosition = location.x - geometry[plotFrame].origin.x
                                if let date: Date = proxy.value(atX: xPosition) {
                                    hoveredPoint = points.min(by: { abs($0.timestamp.timeIntervalSince(date)) < abs($1.timestamp.timeIntervalSince(date)) })
                                }
                            case .ended:
                                hoveredPoint = nil
                            }
                        }
                }
            }
            .frame(height: 240)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor).opacity(0.5))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
        )
    }
    
    // MARK: - Statistics Grid
    private var statisticsGrid: some View {
        HStack(spacing: 14) {
            statCard(
                title: "Peak Value",
                value: String(format: "%.1f %@", historyStore.peakValue, historyStore.selectedMetric.unitLabel),
                subtext: "Maximum recorded",
                color: historyStore.selectedMetric.chartColor
            )
            
            statCard(
                title: "Period Average",
                value: String(format: "%.1f %@", historyStore.averageValue, historyStore.selectedMetric.unitLabel),
                subtext: "Sustained baseline",
                color: .primary
            )
            
            statCard(
                title: "Current Reading",
                value: String(format: "%.1f %@", historyStore.latestValue, historyStore.selectedMetric.unitLabel),
                subtext: "Live sensor output",
                color: .green
            )
            
            statCard(
                title: "Workload Profile",
                value: historyStore.highLoadDurationDescription,
                subtext: "Duration in elevated state",
                color: .secondary
            )
        }
    }
    
    private func statCard(title: String, value: String, subtext: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(color)
                .lineLimit(1)
            
            Text(subtext)
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor).opacity(0.4))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
        )
    }
    
    // MARK: - Highlights Section
    private var highlightsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Activity Highlights")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.primary)
            
            if historyStore.highlights.isEmpty {
                Text("No significant peaks or throttling events during this period.")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 8)
            } else {
                VStack(spacing: 8) {
                    ForEach(historyStore.highlights) { item in
                        HStack(spacing: 12) {
                            Image(systemName: item.iconName)
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(item.color)
                                .frame(width: 28, height: 28)
                                .background(Circle().fill(item.color.opacity(0.12)))
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.title)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(.primary)
                                Text(item.detail)
                                    .font(.system(size: 11))
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            
                            Text(item.timestamp.formatted(date: .abbreviated, time: .shortened))
                                .font(.system(size: 11))
                                .foregroundStyle(.tertiary)
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Color(nsColor: .controlBackgroundColor).opacity(0.4))
                        )
                    }
                }
            }
        }
    }
}
