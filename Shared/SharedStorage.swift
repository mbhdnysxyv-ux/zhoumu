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
        static let hasLaunched = "app.hasCompletedFirstLaunch"
        static let promptMonth = "app.lastSetupPromptMonth"

        /// v1.3 新增
        static let themeMode = "app.themeMode"
        static let liveActivityEnabled = "app.liveActivityEnabled"

        /// v1.2 的扁平课表（迁移用，不再写入）
        static let legacySchedule = "schedule.subjects"
    }

    // MARK: - 快照

    /// 小组件 / 实时活动侧读取的一份设置快照（App 侧用 AppSettings，那个负责写）。
    struct Snapshot {
        var startDate: Date?
        var cycleWeeks: Int
        var cyclingEnabled: Bool
        var themeMode: ThemeMode
        var regular: ScheduleTable
        var evening: ScheduleTable

        init(startDate: Date?,
                    cycleWeeks: Int,
                    cyclingEnabled: Bool,
                    themeMode: ThemeMode = .system,
                    regular: ScheduleTable = .empty(),
                    evening: ScheduleTable = .empty()) {
            self.startDate = startDate
            self.cycleWeeks = cycleWeeks
            self.cyclingEnabled = cyclingEnabled
            self.themeMode = themeMode
            self.regular = regular
            self.evening = evening
        }

        func table(_ kind: ScheduleKind) -> ScheduleTable {
            switch kind {
            case .regular: return regular
            case .evening: return evening
            }
        }

        var tables: [ScheduleKind: ScheduleTable] {
            [.regular: regular, .evening: evening]
        }

        func phase(for date: Date) -> SemesterPhase? {
            guard let startDate else { return nil }
            return SemesterCalculator.phase(startDate: startDate,
                                            cycleWeeks: cycleWeeks,
                                            cyclingEnabled: cyclingEnabled,
                                            referenceDate: date)
        }

        /// 今天显示第几周（不在学期内返回 nil）。
        func displayWeek(for date: Date) -> Int? {
            guard case .inSession(let info)? = phase(for: date) else { return nil }
            return info.displayWeek
        }

        /// 今天按时间轴排好的课程（两张表合并）。
        func classes(for date: Date) -> [ScheduledClass] {
            guard let week = displayWeek(for: date) else { return [] }
            return ClassSchedule.classes(for: date, tables: tables, displayWeek: week)
        }

        /// 此刻的状态。
        func state(at date: Date) -> ClassState {
            ClassSchedule.state(at: date, classes: classes(for: date))
        }
    }

    // MARK: - 读取

    static func load() -> Snapshot {
        let store = defaults

        let interval = store.double(forKey: Key.startDate)
        let storedCycle = store.integer(forKey: Key.cycleWeeks)
        let cycle = SemesterCalculator.cycleWeeksRange.contains(storedCycle) ? storedCycle : 3

        return Snapshot(
            startDate: interval > 0 ? Date(timeIntervalSince1970: interval) : nil,
            cycleWeeks: cycle,
            cyclingEnabled: store.object(forKey: Key.cyclingEnabled) as? Bool ?? true,
            themeMode: ThemeMode(rawValue: store.string(forKey: Key.themeMode) ?? "") ?? .system,
            regular: ScheduleTable.decode(store.string(forKey: ScheduleKind.regular.storageKey)),
            evening: ScheduleTable.decode(store.string(forKey: ScheduleKind.evening.storageKey))
        )
    }

    // MARK: - 写入（小组件侧不用，但实时活动结束回调可能用到）

    static func save(tables: [ScheduleKind: ScheduleTable]) {
        let store = defaults
        for (kind, table) in tables {
            store.set(table.encoded(), forKey: kind.storageKey)
        }
    }
}
