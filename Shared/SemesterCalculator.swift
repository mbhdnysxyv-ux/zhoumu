import Foundation

// MARK: - 结果模型

/// 今天相对于「开学日期」的状态。
enum SemesterPhase: Equatable {
    /// 还没到开学日期。
    case notStarted(daysUntilStart: Int)
    /// 已经开学。
    case inSession(SessionInfo)
}

/// 开学之后的一次计算结果。
struct SessionInfo: Equatable {
    /// 从开学第一天算起的自然周序号（不做循环）：开学第 1 周、第 2 周……
    let rawWeek: Int
    /// 真正展示的周目：开启循环时按 `cycleWeeks` 取模后的结果。
    let displayWeek: Int
    /// 本周是第几天，1...7。
    let dayInWeek: Int
    /// 从开学第一天到今天经过的天数，开学当天为 0。
    let daysSinceStart: Int
    /// 生效的循环长度（周），关闭循环时等于 1。
    let cycleWeeks: Int
    /// 是否开启循环。
    let cyclingEnabled: Bool

    /// 距离下一个周目还有几天。
    var daysUntilNextWeek: Int { 7 - dayInWeek }

    /// 本期周目在环上的进度，1/7...7/7。
    var weekProgress: Double { Double(dayInWeek) / 7.0 }

    /// 是否处于真正的循环中（开启循环且循环长度大于 1）。
    var isCycling: Bool { cyclingEnabled && cycleWeeks > 1 }

    /// 课表用的排索引：开启循环时是「当前显示周目 - 1」，关闭循环时固定第 0 排（每周同一份课表）。
    var scheduleRowIndex: Int { cyclingEnabled ? displayWeek - 1 : 0 }
}

// MARK: - 计算

/// 周目计算：纯函数，方便单独测试。
enum SemesterCalculator {
    /// 循环周数的可选上限。
    static let cycleWeeksRange: ClosedRange<Int> = 1...20

    /// 课表的列名（周一至周日）。
    static let weekdayColumnNames = ["一", "二", "三", "四", "五", "六", "日"]

    /// 星期几的中文短名。
    static let weekdayShortNames = ["周一", "周二", "周三", "周四", "周五", "周六", "周日"]

    /// 星期几的 0 基索引：0 = 周一 … 6 = 周日。
    static func dayIndexInWeek(for date: Date) -> Int {
        // Calendar 里 1 = 周日 … 7 = 周六，换算成「周一为 0」。
        let weekday = calendar.component(.weekday, from: date)
        return (weekday + 5) % 7
    }

    /// 使用的日历：公历 + 中国时区语义（跟随设备时区）。
    static var calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "zh_CN")
        return calendar
    }()

    /// 计算某一天所处的周目。
    ///
    /// 规则：
    /// 1. 以「开学日期」当天为第 1 周的第 1 天，每 7 天进入下一周；
    /// 2. `rawWeek = 天数 / 7 + 1`；
    /// 3. 开启循环时 `displayWeek = (rawWeek - 1) % cycleWeeks + 1`。
    ///
    /// 例：开学第 4 周、循环 3 周 → (4 - 1) % 3 + 1 = 1，显示第 1 周。
    static func phase(startDate: Date,
                      cycleWeeks: Int,
                      cyclingEnabled: Bool,
                      referenceDate: Date = Date()) -> SemesterPhase {
        let start = calendar.startOfDay(for: startDate)
        let today = calendar.startOfDay(for: referenceDate)

        // 用 startOfDay 之间的「天」差值，跨夏令时也不会算错。
        let days = calendar.dateComponents([.day], from: start, to: today).day ?? 0

        guard days >= 0 else {
            return .notStarted(daysUntilStart: -days)
        }

        let rawWeek = days / 7 + 1
        let cycle = min(max(cycleWeeks, cycleWeeksRange.lowerBound), cycleWeeksRange.upperBound)
        let displayWeek = cyclingEnabled ? (rawWeek - 1) % cycle + 1 : rawWeek
        let dayInWeek = days % 7 + 1

        let info = SessionInfo(rawWeek: rawWeek,
                               displayWeek: displayWeek,
                               dayInWeek: dayInWeek,
                               daysSinceStart: days,
                               cycleWeeks: cycle,
                               cyclingEnabled: cyclingEnabled)
        return .inSession(info)
    }
}

// MARK: - 日期文案

extension Date {
    /// 例如：2026年3月18日 星期三
    var zhoumu_fullText: String {
        DateText.fullFormatter.string(from: self)
    }

    /// 例如：3月18日
    var zhoumu_shortText: String {
        DateText.shortFormatter.string(from: self)
    }

    /// 例如：星期三
    var zhoumu_weekdayText: String {
        DateText.weekdayFormatter.string(from: self)
    }

    private enum DateText {
        static let fullFormatter = makeFormatter("yyyy年M月d日 EEEE")
        static let shortFormatter = makeFormatter("yyyy年M月d日")
        static let weekdayFormatter = makeFormatter("EEEE")

        static func makeFormatter(_ format: String) -> DateFormatter {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "zh_CN")
            formatter.calendar = SemesterCalculator.calendar
            formatter.timeZone = .current
            formatter.dateFormat = format
            return formatter
        }
    }
}
