import SwiftUI
import Charts

public struct MetricKPICard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let statusColor: Color
    let trend: String?
    let sparklineData: [Double]
    let isSelected: Bool
    let action: (() -> Void)?
    
    public init(
        title: String,
        value: String,
        subtitle: String,
        icon: String,
        statusColor: Color = .blue,
        trend: String? = nil,
        sparklineData: [Double] = [],
        isSelected: Bool = false,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.value = value
        self.subtitle = subtitle
        self.icon = icon
        self.statusColor = statusColor
        self.trend = trend
        self.sparklineData = sparklineData
        self.isSelected = isSelected
        self.action = action
    }
    
    public var body: some View {
        Button {
            action?()
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                // Header
                HStack(alignment: .center) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(statusColor)
                            .frame(width: 8, height: 8)
                        
                        Text(title.uppercased())
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    if let trend = trend {
                        Text(trend)
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                            .foregroundStyle(trend.hasPrefix("+") ? .orange : .green)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill((trend.hasPrefix("+") ? Color.orange : Color.green).opacity(0.12))
                            )
                    }
                    
                    Image(systemName: icon)
                        .font(.system(size: 12))
                        .foregroundStyle(statusColor)
                }
                
                // Value and mini sparkline
                HStack(alignment: .lastTextBaseline) {
                    Text(value)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                    
                    Spacer()
                    
                    // Sparkline
                    if sparklineData.count > 1 {
                        let normalized = normalize(sparklineData)
                        Chart {
                            ForEach(Array(normalized.enumerated()), id: \.offset) { idx, val in
                                LineMark(
                                    x: .value("Index", idx),
                                    y: .value("Val", val)
                                )
                                .interpolationMethod(.catmullRom)
                                .lineStyle(StrokeStyle(lineWidth: 1.5))
                                .foregroundStyle(statusColor)
                                
                                AreaMark(
                                    x: .value("Index", idx),
                                    y: .value("Val", val)
                                )
                                .interpolationMethod(.catmullRom)
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [statusColor.opacity(0.25), statusColor.opacity(0.0)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                            }
                        }
                        .chartXAxis(.hidden)
                        .chartYAxis(.hidden)
                        .chartLegend(.hidden)
                        .frame(width: 70, height: 28)
                    }
                }
                
                // Subtitle
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color(nsColor: .controlBackgroundColor).opacity(isSelected ? 0.9 : 0.5))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .strokeBorder(
                                isSelected ? statusColor.opacity(0.8) : Color.primary.opacity(0.06),
                                lineWidth: isSelected ? 1.5 : 1
                            )
                    )
            )
        }
        .buttonStyle(.plain)
    }
    
    private func normalize(_ data: [Double]) -> [Double] {
        let maxVal = data.max() ?? 1.0
        guard maxVal > 0 else { return data }
        return data.map { $0 / maxVal }
    }
}
