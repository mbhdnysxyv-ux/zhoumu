import Foundation

/// App 与小组件共享的存储（App Group）。
///
/// group ID **自动从 Bundle ID 推导**，所以换了 `APP_BUNDLE_ID` 之后这里不用改：
/// - 主 App 的 Bundle ID 是 `com.x.y` → group 是 `group.com.x.y`
/// - 小组件的 Bundle ID 是 `com.x.y.widget` → 去掉 `.widget` 后得到同一个 group
///
/// entitlements 文件里写的是 `group.$(APP_BUNDLE_ID)`，Xcode 在构建时展开，两边保持一致。
/// 前提是 `ZhouMu.entitlements` 和 `ZhouMuWidget.entitlements` 都声明了这个 group，
/// 否则两个进程读到的是各自独立的容器（不报错，但数据不互通）。
enum SharedStorage {

    private static let widgetSuffix = ".widget"

    /// App Group 标识。
    static var appGroupID: String {
        let bundleID = Bundle.main.bundleIdentifier ?? "com.zhoumu.weekdisplay"
        let appID = bundleID.hasSuffix(widgetSuffix)
            ? String(bundleID.dropLast(widgetSuffix.count))
            : bundleID
        return "group." + appID
    }

    /// 取共享容器；万一 App Group 没配好就退回标准存储（不会崩，只是读不到对方写的数据）。
    static var defaults: UserDefaults {
        UserDefaults(suiteName: appGroupID) ?? .standard
    }

    /// 两个 target 共用的 key。
    enum Key {
        static let startDate = "semester.startDate"
        static let cycleWeeks = "semester.cycleWeeks"
        static let cyclingEnabled = "semester.cyclingEnabled"
        static let schedule = "schedule.subjects"
        static let hasLaunched = "app.hasCompletedFirstLaunch"
        static let promptMonth = "app.lastSetupPromptMonth"
    }

    /// 课表格子的 key。
    static func scheduleKey(row: Int, day: Int) -> String { "\(row)-\(day)" }

    /// 小组件侧读取的一份设置快照（App 侧用 AppSettings，那个负责写）。
    struct Snapshot {
        var startDate: Date?
        var cycleWeeks: Int
        var cyclingEnabled: Bool
        var schedule: [String: String]

        func phase(for date: Date) -> SemesterPhase? {
            guard let startDate else { return nil }
            return SemesterCalculator.phase(startDate: startDate,
                                            cycleWeeks: cycleWeeks,
                                            cyclingEnabled: cyclingEnabled,
                                            referenceDate: date)
        }

        /// 今天要上的科目；空字符串表示无课。
        func subject(for date: Date) -> String {
            guard case .inSession(let info)? = phase(for: date) else { return "" }
            let day = SemesterCalculator.dayIndexInWeek(for: date)
            return schedule[SharedStorage.scheduleKey(row: info.scheduleRowIndex, day: day)] ?? ""
        }
    }

    static func load() -> Snapshot {
        let store = defaults

        let interval = store.double(forKey: Key.startDate)
        let storedCycle = store.integer(forKey: Key.cycleWeeks)
        let cycle = SemesterCalculator.cycleWeeksRange.contains(storedCycle) ? storedCycle : 3

        return Snapshot(startDate: interval > 0 ? Date(timeIntervalSince1970: interval) : nil,
                        cycleWeeks: cycle,
                        cyclingEnabled: store.object(forKey: Key.cyclingEnabled) as? Bool ?? true,
                        schedule: store.dictionary(forKey: Key.schedule) as? [String: String] ?? [:])
    }
}
