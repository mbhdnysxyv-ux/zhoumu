import AppIntents
import SwiftUI
import WidgetKit

// 设置的来源有两套，按优先级取：
//
// 1. **App Group 共享容器**（首选）：用 Xcode / 自己账号正常安装时，小组件直接读 App 里设好的
//    开学日期、循环周数和课表，改完立刻同步，不用单独设置。
// 2. **小组件自己的配置**（回退）：用自签工具重新签名时，App Group 权限通常会被丢掉，
//    这时小组件读不到共享容器，就退回用「长按小组件 ▸ 编辑小组件」里填的值。
//
// 两条路都走不通时才显示「请先设置」。

// MARK: - 回退用的配置

struct WeekConfigIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "周目设置"
    static var description = IntentDescription("一般不用填：小组件会自动跟随「周目」App。只有读不到 App 设置时（例如自签安装）才需要在这里手动设置。")

    @Parameter(title: "开学日期")
    var startDate: Date?

    @Parameter(title: "循环周数", default: 3)
    var cycleWeeks: Int

    @Parameter(title: "启用循环", default: true)
    var cyclingEnabled: Bool
}

// MARK: - 数据

struct WeekEntry: TimelineEntry {
    let date: Date
    /// nil 表示还没设置开学日期。
    let phase: SemesterPhase?
    /// 今天要上的科目；空字符串表示无课。
    let subject: String
    /// 周目和科目是不是来自 App（用于决定要不要提示用户去设置）。
    let isFromApp: Bool
}

struct WeekProvider: AppIntentTimelineProvider {

    func placeholder(in context: Context) -> WeekEntry {
        WeekEntry(date: Date(),
                  phase: SemesterCalculator.phase(startDate: Date(),
                                                  cycleWeeks: 3,
                                                  cyclingEnabled: true),
                  subject: "数学",
                  isFromApp: true)
    }

    func snapshot(for configuration: WeekConfigIntent, in context: Context) async -> WeekEntry {
        makeEntry(for: configuration, at: Date())
    }

    func timeline(for configuration: WeekConfigIntent, in context: Context) async -> Timeline<WeekEntry> {
        let now = Date()
        // 下一个零点自动刷新（周目和科目只在跨天时变化）。
        let nextMidnight = Calendar.current.nextDate(after: now,
                                                     matching: DateComponents(hour: 0, minute: 0, second: 30),
                                                     matchingPolicy: .nextTime)
            ?? now.addingTimeInterval(3600)
        return Timeline(entries: [makeEntry(for: configuration, at: now)], policy: .after(nextMidnight))
    }

    private func makeEntry(for configuration: WeekConfigIntent, at date: Date) -> WeekEntry {
        // 1) 先看 App 写的共享容器
        let snapshot = SharedStorage.load()
        if snapshot.startDate != nil {
            // 和 App 首页用同一套逻辑：有时间轴取当前科目，没时间回退到当日晚课。
            let content = ClassSchedule.ringContent(at: date,
                                                    tables: snapshot.tables,
                                                    displayWeek: snapshot.displayWeek(for: date))
            return WeekEntry(date: date,
                             phase: snapshot.phase(for: date),
                             subject: content.subject,
                             isFromApp: true)
        }

        // 2) 退回小组件自己的配置
        guard let start = configuration.startDate else {
            return WeekEntry(date: date, phase: nil, subject: "", isFromApp: false)
        }
        let cycle = min(max(configuration.cycleWeeks, SemesterCalculator.cycleWeeksRange.lowerBound),
                        SemesterCalculator.cycleWeeksRange.upperBound)
        let phase = SemesterCalculator.phase(startDate: start,
                                             cycleWeeks: cycle,
                                             cyclingEnabled: configuration.cyclingEnabled,
                                             referenceDate: date)
        return WeekEntry(date: date, phase: phase, subject: "", isFromApp: false)
    }
}

// MARK: - 界面

struct WeekWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    let entry: WeekEntry

    var body: some View {
        content
            .containerBackground(Palette.background, for: .widget)
    }

    @ViewBuilder
    private var content: some View {
        if let phase = entry.phase {
            switch family {
            case .systemMedium:
                mediumBody(phase)
            default:
                smallBody(phase)
            }
        } else {
            promptBody
        }
    }

    // MARK: 小尺寸

    @ViewBuilder
    private func smallBody(_ phase: SemesterPhase) -> some View {
        switch phase {
        case .inSession(let info):
            VStack(spacing: 2) {
                Text(weekdayText)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(Palette.secondaryText)

                if entry.isFromApp {
                    Text(subjectText)
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundStyle(Palette.accent)
                        .lineLimit(2)
                        .minimumScaleFactor(0.5)
                        .multilineTextAlignment(.center)

                    Text("第 \(info.displayWeek) 周")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(Palette.accentDeep)
                } else {
                    Text("第 \(info.displayWeek) 周")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(Palette.accent)
                    Text(subtitle(for: info))
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundStyle(Palette.secondaryText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
            }

        case .notStarted(let days):
            VStack(spacing: 5) {
                Text("未开学")
                    .font(.system(size: 21, weight: .bold, design: .rounded))
                    .foregroundStyle(Palette.accent)
                Text("还有 \(days) 天")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(Palette.secondaryText)
            }
        }
    }

    // MARK: 中尺寸

    @ViewBuilder
    private func mediumBody(_ phase: SemesterPhase) -> some View {
        switch phase {
        case .inSession(let info):
            HStack(spacing: 12) {
                if entry.isFromApp {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(weekdayText)
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(Palette.secondaryText)
                        Text(subjectText)
                            .font(.system(size: 30, weight: .bold, design: .rounded))
                            .foregroundStyle(Palette.accent)
                            .lineLimit(2)
                            .minimumScaleFactor(0.5)
                    }
                } else {
                    Text(subjectText)
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundStyle(Palette.accent)
                }

                Spacer(minLength: 0)

                VStack(alignment: .trailing, spacing: 5) {
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text("第")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                        Text("\(info.displayWeek)")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .monospacedDigit()
                        Text("周")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                    }
                    .foregroundStyle(Palette.accentDeep)

                    if info.isCycling && info.cycleWeeks <= 12 {
                        CycleDots(total: info.cycleWeeks, current: info.displayWeek)
                    }

                    Text(subtitle(for: info))
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundStyle(Palette.secondaryText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
            }

        case .notStarted(let days):
            VStack(alignment: .leading, spacing: 6) {
                Text("未开学")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(Palette.accent)
                Text("距离设定的开学日期还有 \(days) 天")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(Palette.secondaryText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: 还没设置过

    private var promptBody: some View {
        VStack(spacing: 6) {
            Text("第 ? 周")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(Palette.accentSoft)
            Text("打开「周目」App 设置开学日期\n或长按小组件 ▸ 编辑小组件")
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundStyle(Palette.secondaryText)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: 文案

    private var weekdayText: String {
        SemesterCalculator.weekdayShortNames[SemesterCalculator.dayIndexInWeek(for: entry.date)]
    }

    private var subjectText: String {
        entry.subject.isEmpty ? "无课" : entry.subject
    }

    private func subtitle(for info: SessionInfo) -> String {
        info.isCycling
            ? "开学第 \(info.rawWeek) 周 · \(info.cycleWeeks) 周循环"
            : "开学第 \(info.rawWeek) 周"
    }
}

private struct CycleDots: View {
    let total: Int
    let current: Int

    var body: some View {
        HStack(spacing: 4) {
            ForEach(Array(1...max(total, 1)), id: \.self) { index in
                Circle()
                    .fill(index == current ? Palette.accent : Palette.accentSoft)
                    .frame(width: index == current ? 8 : 6,
                       height: index == current ? 8 : 6)
            }
        }
    }
}

// MARK: - 小组件声明

struct WeekWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: "ZhouMuWeekWidget",
                               intent: WeekConfigIntent.self,
                               provider: WeekProvider()) { entry in
            WeekWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("开学周目")
        .description("在桌面直接看到今天第几周、上什么课。正常安装时会自动跟随「周目」App 的设置。")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

@main
struct ZhouMuWidgetBundle: WidgetBundle {
    var body: some Widget {
        WeekWidget()
        // 实时活动必须注册进 WidgetBundle，否则系统扫不到它：
        // 活动能创建成功、SpringBoard 也收得到，但灵动岛和锁屏都不会显示。
        ClassActivityWidget()
    }
}


// MARK: - 灵动岛 / 锁屏实时活动

/// 每节课的实时活动。
///
/// 倒计时和进度条都用 `Text(timerInterval:)` / `ProgressView(timerInterval:)`，
/// **由系统自己渲染**，所以即使 App 没在运行也不会停。
struct ClassActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: ClassActivityAttributes.self) { context in
            LockScreenClassView(context: context)
                .activityBackgroundTint(Palette.card)
                .activitySystemActionForegroundColor(Palette.accent)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Label(context.state.subject, systemImage: symbol(for: context.state.phase))
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(Palette.accent)
                        .lineLimit(1)
                }

                DynamicIslandExpandedRegion(.trailing) {
                    ClassCountdown(state: context.state, size: 15)
                        .foregroundStyle(Palette.accentDeep)
                }

                DynamicIslandExpandedRegion(.center) {
                    Text(context.state.caption)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(Palette.secondaryText)
                }

                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 6) {
                        ClassProgress(state: context.state)

                        if let next = context.state.nextStart, next > Date() {
                            HStack {
                                Text("下节")
                                    .foregroundStyle(Palette.secondaryText)
                                Spacer()
                                Text(timerInterval: Date()...next, countsDown: true)
                                    .monospacedDigit()
                                    .foregroundStyle(Palette.accentDeep)
                            }
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                        }
                    }
                }
            } compactLeading: {
                Image(systemName: symbol(for: context.state.phase))
                    .foregroundStyle(Palette.accent)
            } compactTrailing: {
                ClassCountdown(state: context.state, size: 13)
                    .monospacedDigit()
                    .foregroundStyle(Palette.accentDeep)
            } minimal: {
                Image(systemName: symbol(for: context.state.phase))
                    .foregroundStyle(Palette.accent)
            }
            .keylineTint(Palette.accent)
        }
    }

    private func symbol(for phase: String) -> String {
        switch phase {
        case "in":      return "book.closed.fill"
        case "rest":    return "cup.and.saucer.fill"
        case "done":    return "checkmark.circle.fill"
        case "none":    return "moon.zzz.fill"
        case "evening": return "moon.stars.fill"
        default:        return "bell.fill"
        }
    }
}

/// 锁屏上的卡片。
private struct LockScreenClassView: View {
    let context: ActivityViewContext<ClassActivityAttributes>

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(context.state.caption)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(Palette.secondaryText)

                Spacer()

                Text(context.attributes.dayTitle)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(Palette.secondaryText)
            }

            HStack(alignment: .firstTextBaseline) {
                Text(context.state.subject)
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(Palette.accent)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)

                Spacer(minLength: 10)

                ClassCountdown(state: context.state, size: 17)
                    .monospacedDigit()
                    .foregroundStyle(Palette.accentDeep)
            }

            ClassProgress(state: context.state)

            if !context.attributes.items.isEmpty {
                Divider().overlay(Palette.line)

                VStack(spacing: 4) {
                    ForEach(context.attributes.items.prefix(5)) { item in
                        HStack(spacing: 8) {
                            Text(item.subject)
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundStyle(Palette.primaryText)
                            Spacer(minLength: 6)
                            Text("\(timeText(item.start)) – \(timeText(item.end))")
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundStyle(Palette.secondaryText)
                                .monospacedDigit()
                        }
                    }
                }
            }
        }
        .padding(14)
    }

    private func timeText(_ date: Date) -> String {
        let c = SemesterCalculator.calendar.dateComponents([.hour, .minute], from: date)
        return String(format: "%d:%02d", c.hour ?? 0, c.minute ?? 0)
    }
}

/// 倒计时文案：上课中显示「还剩」，否则显示「距上课」。
private struct ClassCountdown: View {
    let state: ClassActivityAttributes.ContentState
    let size: CGFloat

    var body: some View {
        Group {
            if let end = state.currentEnd, end > Date() {
                Text(timerInterval: Date()...end, countsDown: true)
            } else if let start = state.nextStart, start > Date() {
                Text(timerInterval: Date()...start, countsDown: true)
            } else {
                Text("—")
            }
        }
        .font(.system(size: size, weight: .bold, design: .rounded))
        .multilineTextAlignment(.trailing)
    }
}

/// 进度条：上课中随这节课的进度走，由系统自绘。
private struct ClassProgress: View {
    let state: ClassActivityAttributes.ContentState

    var body: some View {
        Group {
            if let start = state.currentStart, let end = state.currentEnd, end > start {
                ProgressView(timerInterval: start...end, countsDown: false)
                    .tint(Palette.accent)
            } else if state.phase == "rest" || state.phase == "done" {
                ProgressView(value: 1.0)
                    .tint(Palette.accent)
            } else {
                ProgressView(value: 0.0)
                    .tint(Palette.accent)
            }
        }
        .labelsHidden()
    }
}
