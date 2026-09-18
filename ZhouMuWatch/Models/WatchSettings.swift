import Combine
import Foundation
#if canImport(WatchKit)
import WatchKit
#endif

/// 手表端的设置。独立手表应用，所有东西都在表上设。
final class WatchSettings: ObservableObject {

    @Published var startDate: Date { didSet { persist() } }
    @Published var cycleWeeks: Int { didSet { persist() } }
    @Published var cyclingEnabled: Bool { didSet { persist() } }
    @Published var table: ScheduleTable { didSet { persist() } }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = WatchStorage.defaults) {
        self.defaults = defaults
        let interval = defaults.double(forKey: WatchStorage.Key.startDate)
        startDate = interval > 0
            ? Date(timeIntervalSince1970: interval)
            : SemesterCalculator.calendar.startOfDay(for: Date())

        let stored = defaults.integer(forKey: WatchStorage.Key.cycleWeeks)
        cycleWeeks = SemesterCalculator.cycleWeeksRange.contains(stored) ? stored : 3
        cyclingEnabled = defaults.object(forKey: WatchStorage.Key.cyclingEnabled) as? Bool ?? true
        table = ScheduleTable.decode(defaults.string(forKey: WatchStorage.Key.schedule))
    }

    var phase: SemesterPhase {
        SemesterCalculator.phase(startDate: startDate,
                                 cycleWeeks: cycleWeeks,
                                 cyclingEnabled: cyclingEnabled)
    }

    /// 今天按周目取到的课（一整天逐节列出）。
    func todayClasses(referenceDate: Date = Date()) -> [(period: Int, subject: String, time: String?)] {
        guard case .inSession(let info) = SemesterCalculator.phase(
            startDate: startDate, cycleWeeks: cycleWeeks,
            cyclingEnabled: cyclingEnabled, referenceDate: referenceDate) else { return [] }

        let day = SemesterCalculator.dayIndexInWeek(for: referenceDate)
        let row = table.rotatesByWeek ? max(0, info.displayWeek - 1) : 0
        var out: [(Int, String, String?)] = []
        for period in 0..<table.periodCount(day: day) {
            let subject = table.subject(row: row, day: day, period: period)
            guard !subject.isEmpty else { continue }
            var time: String?
            if let t = table.time(forPeriod: period) {
                time = "\(t.start / 60):\(String(format: "%02d", t.start % 60))"
            }
            out.append((period + 1, subject, time))
        }
        return out
    }

    private func persist() {
        defaults.set(startDate.timeIntervalSince1970, forKey: WatchStorage.Key.startDate)
        defaults.set(cycleWeeks, forKey: WatchStorage.Key.cycleWeeks)
        defaults.set(cyclingEnabled, forKey: WatchStorage.Key.cyclingEnabled)
        defaults.set(table.encoded(), forKey: WatchStorage.Key.schedule)
    }
}
