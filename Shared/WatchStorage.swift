import Foundation

/// 手表端与表盘复杂功能共享的存储。
///
/// 用 App Group 让「App 进程」和「复杂功能扩展」读到同一份设置——
/// 和 iOS 版同样的思路，只是这里的 group 是手表自己的。
enum WatchStorage {

    private static let widgetSuffix = ".widget"

    static var appGroupID: String {
        let bundleID = Bundle.main.bundleIdentifier ?? "com.zhoumu.weekdisplay"
        var appID = bundleID
        // 复杂功能跑在 <app>.widget 里，去掉后缀才能拿到同一个 App Group。
        if appID.hasSuffix(widgetSuffix) { appID = String(appID.dropLast(widgetSuffix.count)) }
        // 手表 App 的 bundle id 是 <主App>.watchkitapp，同样要剥掉。
        let watchSuffix = ".watchkitapp"
        if appID.hasSuffix(watchSuffix) { appID = String(appID.dropLast(watchSuffix.count)) }
        return "group." + appID
    }

    static var defaults: UserDefaults {
        UserDefaults(suiteName: appGroupID) ?? .standard
    }

    enum Key {
        static let startDate = "semester.startDate"
        static let cycleWeeks = "semester.cycleWeeks"
        static let cyclingEnabled = "semester.cyclingEnabled"
        static let schedule = "schedule.table"
    }

    /// 复杂功能侧读的一份快照。
    struct Snapshot {
        var startDate: Date?
        var cycleWeeks: Int
        var cyclingEnabled: Bool
        var table: ScheduleTable

        func phase(for date: Date) -> SemesterPhase? {
            guard let startDate else { return nil }
            return SemesterCalculator.phase(startDate: startDate,
                                            cycleWeeks: cycleWeeks,
                                            cyclingEnabled: cyclingEnabled,
                                            referenceDate: date)
        }

        /// 表盘上显示的：第几周 + 今天上什么。
        ///
        /// 有时间轴就用「当前正在上的那一节」；没填时间（或今天还没到点）
        /// 就退回「今天第一节」——手表只有一张课表，不能像 iOS 版那样退到晚课表。
        func headline(for date: Date) -> (week: Int, subject: String)? {
            guard case .inSession(let info) = phase(for: date) else { return nil }
            let day = SemesterCalculator.dayIndexInWeek(for: date)

            let content = ClassSchedule.ringContent(at: date,
                                                    tables: [.regular: table],
                                                    displayWeek: info.displayWeek)
            let timed = content.subject
            if !timed.isEmpty, timed != "无课", timed != "完课" {
                return (info.displayWeek, timed)
            }
            let fallback = ClassSchedule.firstSubject(day: day, table: table,
                                                      displayWeek: info.displayWeek)
            return (info.displayWeek, fallback ?? "无课")
        }
    }

    static func load() -> Snapshot {
        let store = defaults
        let interval = store.double(forKey: Key.startDate)
        let stored = store.integer(forKey: Key.cycleWeeks)
        let cycle = SemesterCalculator.cycleWeeksRange.contains(stored) ? stored : 3
        return Snapshot(startDate: interval > 0 ? Date(timeIntervalSince1970: interval) : nil,
                        cycleWeeks: cycle,
                        cyclingEnabled: store.object(forKey: Key.cyclingEnabled) as? Bool ?? true,
                        table: ScheduleTable.decode(store.string(forKey: Key.schedule)))
    }
}
