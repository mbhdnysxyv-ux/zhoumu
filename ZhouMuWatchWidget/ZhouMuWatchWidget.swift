import SwiftUI
import WidgetKit

/// 表盘上的复杂功能：一眼看到第几周。
struct WeekEntry: TimelineEntry {
    let date: Date
    /// nil 表示还没设开学日期。
    let phase: SemesterPhase?
    /// 今天第一节的科目，空字符串表示今天没课。
    let firstSubject: String
}

struct WeekProvider: TimelineProvider {
    func placeholder(in context: Context) -> WeekEntry {
        WeekEntry(date: Date(), phase: nil, firstSubject: "数学")
    }

    func getSnapshot(in context: Context, completion: @escaping (WeekEntry) -> Void) {
        completion(entry(for: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WeekEntry>) -> Void) {
        let now = Date()
        // 跨零点后要重算，所以下一个刷新点放在明天 00:00:30。
        let nextMidnight = Calendar.current.nextDate(after: now,
                                                     matching: DateComponents(hour: 0, minute: 0, second: 30),
                                                     matchingPolicy: .nextTime)
            ?? now.addingTimeInterval(3600)
        completion(Timeline(entries: [entry(for: now)], policy: .after(nextMidnight)))
    }

    private func entry(for date: Date) -> WeekEntry {
        let snapshot = WatchStorage.load()
        let phase = snapshot.phase(for: date)

        var first = ""
        if case .inSession(let info) = phase {
            let day = SemesterCalculator.dayIndexInWeek(for: date)
            let row = snapshot.table.rotatesByWeek ? max(0, info.displayWeek - 1) : 0
            for period in 0..<snapshot.table.periodCount(day: day) {
                let subject = snapshot.table.subject(row: row, day: day, period: period)
                if !subject.isEmpty { first = subject; break }
            }
        }
        return WeekEntry(date: date, phase: phase, firstSubject: first)
    }
}

struct WeekWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: WeekEntry

    var body: some View {
        content
            .containerBackground(for: .widget) { Color.clear }
    }

    @ViewBuilder
    private var content: some View {
        switch entry.phase {
        case .inSession(let info):
            switch family {
            case .accessoryInline:
                Text("第 \(info.displayWeek) 周" + (entry.firstSubject.isEmpty ? "" : " · \(entry.firstSubject)"))

            case .accessoryRectangular:
                VStack(alignment: .leading, spacing: 1) {
                    Text("第 \(info.displayWeek) 周")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                    Text(entry.firstSubject.isEmpty ? "今天没课" : "今天：\(entry.firstSubject)")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

            case .accessoryCorner:
                Text("\(info.displayWeek)")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .widgetLabel("周")

            default:  // accessoryCircular
                Gauge(value: info.weekProgress) {
                    Text("周")
                } currentValueLabel: {
                    Text("\(info.displayWeek)")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                }
                .gaugeStyle(.accessoryCircular)
            }

        case .notStarted(let days):
            Text("还有 \(days) 天")

        case .none:
            Text("未设置")
        }
    }
}

struct WeekComplication: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "ZhouMuWeekComplication", provider: WeekProvider()) { entry in
            WeekWidgetView(entry: entry)
        }
        .configurationDisplayName("开学周目")
        .description("在表盘上直接看到今天第几周。")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular,
                            .accessoryInline, .accessoryCorner])
    }
}

@main
struct ZhouMuWatchWidgetBundle: WidgetBundle {
    var body: some Widget {
        WeekComplication()
    }
}
