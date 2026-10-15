import SwiftUI
import Charts

public enum TimelineRange: String, CaseIterable, Identifiable {
    case oneMinute = "1m"
    case fiveMinutes = "5m"
    case tenMinutes = "10m"
    
    public var id: String { rawValue }
    
    public var seconds: TimeInterval {
        switch self {
        case .oneMinute: return 60
        case .fiveMinutes: return 300
        case .tenMinutes: return 600
        }
    }
}

public struct TimelineDataPoint: Identifiable {
    public let id = UUID()
    public let timestamp: Date
    public let value: Double
    
    public init(timestamp: Date, value: Double) {
        self.timestamp = timestamp
        self.value = value
    }
}

public struct TimelineChartView: View {
    let title: String
    let currentFormattedValue: String
    let unitLabel: String
    let dataPoints: [TimelineDataPoint]
    let accentColor: Color
    let maxY: Double?
    
    @State private var selectedRange: TimelineRange = .fiveMinutes
    @State private var hoveredTimestamp: Date? = nil
    
    public init(
        title: String,
        currentFormattedValue: String,
        unitLabel: String = "%",
        dataPoints: [TimelineDataPoint],
        accentColor: Color = .blue,
        maxY: Double? = nil
    ) {
        self.title = title
        self.currentFormattedValue = currentFormattedValue
        self.unitLabel = unitLabel
        self.dataPoints = dataPoints
        self.accentColor = accentColor
        self.maxY = maxY
    }
    
    private var filteredData: [TimelineDataPoint] {
        let cutoff = Date().addingTimeInterval(-selectedRange.seconds)
        let slice = dataPoints.filter { $0.timestamp >= cutoff }
        if slice.isEmpty && !dataPoints.isEmpty {
            return dataPoints
        }
        return slice
    }
    
    private var hoveredPoint: TimelineDataPoint? {
        guard let hovered = hoveredTimestamp else { return nil }
        return filteredData.min(by: {
            abs($0.timestamp.timeIntervalSince(hovered)) < abs($1.timestamp.timeIntervalSince(hovered))
        })
    }
    
    public var body: some View {
        VStack(spacing: 12) {
            // Chart Header
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title.uppercased())
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.secondary)
                    
                    HStack(spacing: 8) {
                        Text(hoveredPoint != nil ? formatHoveredValue(hoveredPoint!.value) : currentFormattedValue)
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundStyle(.primary)
                        
                        if let hp = hoveredPoint {
                            Text(formatTime(hp.timestamp))
                                .font(.system(size: 11, weight: .medium, design: .monospaced))
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(Color.primary.opacity(0.08)))
                        }
                    }
                }
                
                Spacer()
                
                // Range Picker (1m, 5m, 10m)
                HStack(spacing: 2) {
                    ForEach(TimelineRange.allCases) { range in
                        Button {
                            selectedRange = range
                        } label: {
                            Text(range.rawValue)
                                .font(.system(size: 11, weight: selectedRange == range ? .bold : .medium))
                                .foregroundStyle(selectedRange == range ? Color.primary : Color.secondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                                        .fill(selectedRange == range ? Color(nsColor: .controlColor) : Color.clear)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(3)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color(nsColor: .controlBackgroundColor).opacity(0.5))
                )
            }
            
            // Chart Body
            Chart {
                ForEach(filteredData) { pt in
                    LineMark(
                        x: .value("Time", pt.timestamp),
                        y: .value("Value", pt.value)
                    )
                    .interpolationMethod(.catmullRom)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                    .foregroundStyle(accentColor)
                    
                    AreaMark(
                        x: .value("Time", pt.timestamp),
                        y: .value("Value", pt.value)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [accentColor.opacity(0.35), accentColor.opacity(0.02)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }
                
                // Hover Crosshair Rule
                if let hp = hoveredPoint {
                    RuleMark(x: .value("Selected", hp.timestamp))
                        .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [4, 4]))
                        .foregroundStyle(Color.primary.opacity(0.5))
                        .annotation(position: .top, spacing: 4) {
                            Text(formatHoveredValue(hp.value))
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(
                                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                                        .fill(Color(nsColor: .windowBackgroundColor))
                                        .shadow(color: .black.opacity(0.2), radius: 3)
                                )
                        }
                    
                    PointMark(
                        x: .value("Selected", hp.timestamp),
                        y: .value("Value", hp.value)
                    )
                    .symbolSize(36)
                    .foregroundStyle(accentColor)
                }
            }
            .chartYScale(domain: 0...(maxY ?? (filteredData.map(\.value).max().map { max($0 * 1.2, 10.0) } ?? 100.0)))
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 5)) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [2, 2]))
                        .foregroundStyle(Color.primary.opacity(0.08))
                    AxisTick()
                    if let date = value.as(Date.self) {
                        AxisValueLabel {
                            Text(formatAxisTime(date))
                                .font(.system(size: 10))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .trailing, values: .automatic(desiredCount: 4)) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [2, 2]))
                        .foregroundStyle(Color.primary.opacity(0.08))
                    if let val = value.as(Double.self) {
                        AxisValueLabel {
                            Text(formatAxisY(val))
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .chartXSelection(value: $hoveredTimestamp)
            .frame(height: 180)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor).opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
                )
        )
    }
    
    private func formatHoveredValue(_ val: Double) -> String {
        if unitLabel == "%" {
            return String(format: "%.1f%%", val)
        }
        let formatter = ByteCountFormatter()
        formatter.countStyle = .memory
        return formatter.string(fromByteCount: Int64(val))
    }
    
    private func formatAxisY(_ val: Double) -> String {
        if unitLabel == "%" {
            return "\(Int(val))%"
        }
        let formatter = ByteCountFormatter()
        formatter.countStyle = .memory
        return formatter.string(fromByteCount: Int64(val))
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: date)
    }
    
    private func formatAxisTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}
