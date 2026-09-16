import Combine
import Foundation
#if os(iOS)
import WidgetKit
#endif

/// 本地设置存储 + 启动时是否需要弹出「开学设置」的判定。
///
/// 弹出规则：
/// - 第一次启动，一定弹；
/// - 之后只在「放假开始月」（1 月、7 月）弹，且每个月只弹一次；
/// - 其余月份启动不弹。
final class AppSettings: ObservableObject {

    /// 放假开始月：1 月（寒假开始）、7 月（暑假开始）。
    static let vacationStartMonths: Set<Int> = [1, 7]

    /// 开学日期。
    @Published var startDate: Date {
        didSet { persist() }
    }

    /// 循环周数（开启循环时生效）。
    @Published var cycleWeeks: Int {
        didSet { persist() }
    }

    /// 是否开启周目循环。
    @Published var cyclingEnabled: Bool {
        didSet { persist() }
    }

    /// 是否已经完成过首次启动（首次启动必须引导设置）。
    private(set) var hasCompletedFirstLaunch: Bool

    /// 上一次弹出开学设置的月份，格式 "yyyy-MM"。
    private(set) var lastSetupPromptMonth: String?

    /// 课表：key 为 "排-列"（都是 0 基），value 是科目名。
    /// 没有 key 就表示这一格是「无」。
    @Published var schedule: [String: String] {
        didSet { persist() }
    }

    private let defaults: UserDefaults

    /// 统一指向共享存储的 key，保证 App 和小组件读写的名字一致。
    private enum Key {
        static let startDate = SharedStorage.Key.startDate
        static let cycleWeeks = SharedStorage.Key.cycleWeeks
        static let cyclingEnabled = SharedStorage.Key.cyclingEnabled
        static let hasLaunched = SharedStorage.Key.hasLaunched
        static let promptMonth = SharedStorage.Key.promptMonth
        static let schedule = SharedStorage.Key.schedule
    }

    init(defaults: UserDefaults = SharedStorage.defaults) {
        self.defaults = defaults

        // 之前版本写在标准 UserDefaults 里，切到 App Group 后要把旧数据搬过来，避免用户丢设置。
        if defaults === SharedStorage.defaults {
            Self.migrateLegacySettingsIfNeeded(to: defaults)
        }

        let storedInterval = defaults.double(forKey: Key.startDate)
        if storedInterval > 0 {
            startDate = Date(timeIntervalSince1970: storedInterval)
        } else {
            startDate = SemesterCalculator.calendar.startOfDay(for: Date())
        }

        let storedCycle = defaults.integer(forKey: Key.cycleWeeks)
        cycleWeeks = SemesterCalculator.cycleWeeksRange.contains(storedCycle) ? storedCycle : 3
        cyclingEnabled = defaults.object(forKey: Key.cyclingEnabled) as? Bool ?? true
        hasCompletedFirstLaunch = defaults.bool(forKey: Key.hasLaunched)
        lastSetupPromptMonth = defaults.string(forKey: Key.promptMonth)
        schedule = defaults.dictionary(forKey: Key.schedule) as? [String: String] ?? [:]
    }

    // MARK: - 课表

    /// 课表有几排：开启循环时等于循环周数，关闭循环时只有一排（每周同一份课表）。
    var scheduleRowCount: Int {
        cyclingEnabled ? cycleWeeks : 1
    }

    static func scheduleKey(row: Int, day: Int) -> String {
        SharedStorage.scheduleKey(row: row, day: day)
    }

    /// 取某一格的科目名，空格子返回空字符串（= 无）。
    func subject(row: Int, day: Int) -> String {
        schedule[Self.scheduleKey(row: row, day: day)] ?? ""
    }

    /// 设置某一格的科目名；传空字符串或只有空白，就表示这一格设为「无」。
    func setSubject(_ text: String, row: Int, day: Int) {
        let key = Self.scheduleKey(row: row, day: day)
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            schedule.removeValue(forKey: key)
        } else {
            schedule[key] = trimmed
        }
    }

    /// 今天要上的科目（空字符串表示无课）。
    func subjectForToday(referenceDate: Date = Date()) -> String {
        guard case .inSession(let info) = SemesterCalculator.phase(startDate: startDate,
                                                                   cycleWeeks: cycleWeeks,
                                                                   cyclingEnabled: cyclingEnabled,
                                                                   referenceDate: referenceDate) else {
            return ""
        }
        let day = SemesterCalculator.dayIndexInWeek(for: referenceDate)
        return subject(row: info.scheduleRowIndex, day: day)
    }

    /// 课表里是否至少填了一个科目。
    var hasAnySubject: Bool {
        !schedule.isEmpty
    }

    // MARK: - 启动弹窗判定

    /// 本次启动是否应该弹出开学设置。
    var shouldPresentSetupOnLaunch: Bool {
        setupPromptNeeded(at: Date(), calendar: SemesterCalculator.calendar)
    }

    /// 判定逻辑单独抽出，方便测试。
    func setupPromptNeeded(at date: Date, calendar: Calendar = SemesterCalculator.calendar) -> Bool {
        if !hasCompletedFirstLaunch { return true }
        guard Self.isVacationStartMonth(date, calendar: calendar) else { return false }
        return lastSetupPromptMonth != Self.monthKey(date, calendar: calendar)
    }

    /// 弹窗展示后调用：记录「首次启动已完成」以及「本月已弹过」。
    func markSetupPrompted(at date: Date = Date(), calendar: Calendar = SemesterCalculator.calendar) {
        if !hasCompletedFirstLaunch {
            hasCompletedFirstLaunch = true
            defaults.set(true, forKey: Key.hasLaunched)
        }
        if Self.isVacationStartMonth(date, calendar: calendar) {
            let key = Self.monthKey(date, calendar: calendar)
            lastSetupPromptMonth = key
            defaults.set(key, forKey: Key.promptMonth)
        }
    }

    /// 让下次启动重新弹出开学设置（设置页里的手动入口）。
    func resetSetupPromptHistory() {
        hasCompletedFirstLaunch = false
        lastSetupPromptMonth = nil
        defaults.set(false, forKey: Key.hasLaunched)
        defaults.removeObject(forKey: Key.promptMonth)
    }

    // MARK: - 工具

    static func isVacationStartMonth(_ date: Date, calendar: Calendar = SemesterCalculator.calendar) -> Bool {
        vacationStartMonths.contains(calendar.component(.month, from: date))
    }

    static func monthKey(_ date: Date, calendar: Calendar = SemesterCalculator.calendar) -> String {
        let parts = calendar.dateComponents([.year, .month], from: date)
        return String(format: "%04d-%02d", parts.year ?? 0, parts.month ?? 0)
    }

    // MARK: - 持久化

    private func persist() {
        defaults.set(startDate.timeIntervalSince1970, forKey: Key.startDate)
        defaults.set(cycleWeeks, forKey: Key.cycleWeeks)
        defaults.set(cyclingEnabled, forKey: Key.cyclingEnabled)
        defaults.set(schedule, forKey: Key.schedule)
        reloadWidgets()
    }

    /// App 里改完设置，让桌面小组件立刻跟着变（不用等系统的刷新周期）。
    private func reloadWidgets() {
        #if os(iOS)
        WidgetCenter.shared.reloadAllTimelines()
        #endif
    }

    /// 把旧版本写在标准 UserDefaults 里的设置搬到 App Group 容器。
    private static func migrateLegacySettingsIfNeeded(to shared: UserDefaults) {
        // 共享容器里已经有开学日期 → 不需要迁移
        guard shared.double(forKey: Key.startDate) <= 0 else { return }

        let legacy = UserDefaults.standard
        guard legacy.double(forKey: Key.startDate) > 0 else { return }

        for key in [Key.startDate, Key.cycleWeeks, Key.cyclingEnabled,
                    Key.hasLaunched, Key.promptMonth, Key.schedule] {
            if let value = legacy.object(forKey: key) {
                shared.set(value, forKey: key)
            }
        }
    }
}
