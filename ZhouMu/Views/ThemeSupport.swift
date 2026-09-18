import SwiftUI

extension ThemeMode {
    /// 设置页里显示的小图标。
    var iconName: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light:  return "sun.max.fill"
        case .dark:   return "moon.fill"
        }
    }
}

// MARK: - 时长文案

enum DurationText {

    /// 「12 分钟」「1 小时 5 分钟」「不到 1 分钟」。
    static func human(_ interval: TimeInterval) -> String {
        let seconds = Int(interval.rounded())
        if seconds <= 0 { return "不到 1 分钟" }
        let minutes = seconds / 60
        if minutes < 1 { return "不到 1 分钟" }
        if minutes < 60 { return "\(minutes) 分钟" }
        let h = minutes / 60
        let m = minutes % 60
        return m == 0 ? "\(h) 小时" : "\(h) 小时 \(m) 分钟"
    }

    /// 圆环和倒计时用的紧凑格式：`mm:ss`（超过一小时则 `h:mm:ss`）。
    static func clock(_ interval: TimeInterval) -> String {
        let total = max(0, Int(interval.rounded()))
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        return h > 0
            ? String(format: "%d:%02d:%02d", h, m, s)
            : String(format: "%02d:%02d", m, s)
    }

    /// 「8:00」这种时刻文案。
    static func timeOfDay(_ date: Date, calendar: Calendar = SemesterCalculator.calendar) -> String {
        let c = calendar.dateComponents([.hour, .minute], from: date)
        return String(format: "%d:%02d", c.hour ?? 0, c.minute ?? 0)
    }

    /// 分钟数（从 0:00 起）→「8:00」。
    static func timeOfDay(minutes: Int) -> String {
        String(format: "%d:%02d", minutes / 60, minutes % 60)
    }
}

// MARK: - 卡片外观

/// v1.3 统一的卡片底：圆角 + 卡片色 + 柔和阴影。
struct CardBackground: ViewModifier {
    var padding: CGFloat = 20
    var radius: CGFloat = 26

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(Palette.card)
                    .shadow(color: Palette.accent.opacity(0.10), radius: 18, x: 0, y: 8)
            )
    }
}

extension View {
    func cardStyle(padding: CGFloat = 20, radius: CGFloat = 26) -> some View {
        modifier(CardBackground(padding: padding, radius: radius))
    }
}
