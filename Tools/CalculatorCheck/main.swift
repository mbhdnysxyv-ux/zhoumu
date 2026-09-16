// 周目计算逻辑的本地校验（不依赖模拟器）。
// 用法：swiftc -O Tools/CalculatorCheck/main.swift ZhouMu/Models/SemesterCalculator.swift ZhouMu/Models/AppSettings.swift -o /tmp/zhoumu-check && /tmp/zhoumu-check
import Combine
import Foundation

var failures = 0
var checks = 0

func expect(_ condition: Bool, _ message: String) {
    checks += 1
    if condition {
        print("  ✓ \(message)")
    } else {
        failures += 1
        print("  ✗ \(message)")
    }
}

func expectEqual<T: Equatable>(_ actual: T, _ expected: T, _ message: String) {
    expect(actual == expected, "\(message)（期望 \(expected)，实际 \(actual)）")
}

let shanghai = TimeZone(identifier: "Asia/Shanghai")!

func day(_ year: Int, _ month: Int, _ dayOfMonth: Int, timeZone: TimeZone? = nil) -> Date {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = timeZone ?? shanghai
    return calendar.date(from: DateComponents(year: year,
                                              month: month,
                                              day: dayOfMonth,
                                              hour: 12))!
}

/// 取出 inSession 结果，否则报错。
func session(_ phase: SemesterPhase, _ message: String) -> SessionInfo? {
    if case .inSession(let info) = phase { return info }
    expect(false, "\(message)：应为已开学状态")
    return nil
}

SemesterCalculator.calendar.timeZone = shanghai

// MARK: - 1. 用户给的例子：开学第 4 周 + 循环 3 周 → 第 1 周

print("\n[1] 例子：开学第 4 周、循环 3 周 → 显示第 1 周")
let start = day(2026, 2, 23)
// 开学第 4 周 = 第 21...27 天；第 5 周 = 28...34；第 6 周 = 35...41；第 7 周 = 42 天起。
for (offset, expectedDisplay) in [(21, 1), (22, 1), (27, 1), (28, 2), (34, 2), (35, 3), (42, 1)] {
    let target = day(2026, 2, 23 + offset)
    let phase = SemesterCalculator.phase(startDate: start,
                                         cycleWeeks: 3,
                                         cyclingEnabled: true,
                                         referenceDate: target)
    if let info = session(phase, "第 \(offset) 天") {
        expectEqual(info.rawWeek, offset / 7 + 1, "第 \(offset) 天是开学第几周")
        expectEqual(info.displayWeek, expectedDisplay, "第 \(offset) 天显示的周目")
    }
}

// MARK: - 2. 循环取模的完整一轮

print("\n[2] 循环 3 周时，开学第 1...7 周的显示")
let expectedCycle = [1, 2, 3, 1, 2, 3, 1]
for (index, expected) in expectedCycle.enumerated() {
    let target = day(2026, 2, 23 + index * 7)
    let phase = SemesterCalculator.phase(startDate: start,
                                         cycleWeeks: 3,
                                         cyclingEnabled: true,
                                         referenceDate: target)
    if let info = session(phase, "第 \(index + 1) 周") {
        expectEqual(info.rawWeek, index + 1, "开学第 \(index + 1) 周")
        expectEqual(info.displayWeek, expected, "开学第 \(index + 1) 周显示为")
    }
}

// MARK: - 3. 开学当天、周内天数

print("\n[3] 开学当天与周内天数")
if let info = session(SemesterCalculator.phase(startDate: start,
                                               cycleWeeks: 4,
                                               cyclingEnabled: true,
                                               referenceDate: start),
                      "开学当天") {
    expectEqual(info.rawWeek, 1, "开学当天是第 1 周")
    expectEqual(info.displayWeek, 1, "开学当天显示第 1 周")
    expectEqual(info.dayInWeek, 1, "开学当天是本周第 1 天")
    expectEqual(info.daysSinceStart, 0, "开学当天已过 0 天")
    expectEqual(info.daysUntilNextWeek, 6, "开学当天距下一周目还有 6 天")
}

for (offset, expectedDay) in [(0, 1), (5, 6), (6, 7), (7, 1), (13, 7)] {
    let target = day(2026, 2, 23 + offset)
    if let info = session(SemesterCalculator.phase(startDate: start,
                                                   cycleWeeks: 4,
                                                   cyclingEnabled: true,
                                                   referenceDate: target),
                          "第 \(offset) 天") {
        expectEqual(info.dayInWeek, expectedDay, "第 \(offset) 天是本周第几天")
    }
}

// MARK: - 4. 关闭循环 / 循环为 1

print("\n[4] 关闭循环与循环为 1 周")
let week4 = day(2026, 3, 16) // 开学第 4 周
if let info = session(SemesterCalculator.phase(startDate: start,
                                               cycleWeeks: 3,
                                               cyclingEnabled: false,
                                               referenceDate: week4),
                      "关闭循环") {
    expectEqual(info.rawWeek, 4, "关闭循环时仍是开学第 4 周")
    expectEqual(info.displayWeek, 4, "关闭循环时直接显示第 4 周")
    expect(!info.isCycling, "关闭循环时 isCycling 为 false")
}
if let info = session(SemesterCalculator.phase(startDate: start,
                                               cycleWeeks: 1,
                                               cyclingEnabled: true,
                                               referenceDate: week4),
                      "循环 1 周") {
    expectEqual(info.displayWeek, 1, "循环 1 周时永远显示第 1 周")
}

// MARK: - 5. 未开学

print("\n[5] 开学日期之前")
let before = day(2026, 2, 18)
let beforePhase = SemesterCalculator.phase(startDate: start,
                                           cycleWeeks: 3,
                                           cyclingEnabled: true,
                                           referenceDate: before)
if case .notStarted(let days) = beforePhase {
    expectEqual(days, 5, "距离开学还有 5 天")
} else {
    expect(false, "开学前应返回 notStarted")
}
let yesterday = day(2026, 2, 22)
if case .notStarted(let days) = SemesterCalculator.phase(startDate: start,
                                                         cycleWeeks: 3,
                                                         cyclingEnabled: true,
                                                         referenceDate: yesterday) {
    expectEqual(days, 1, "开学前一天显示还有 1 天")
} else {
    expect(false, "开学前一天应返回 notStarted")
}

// MARK: - 6. 循环超过一轮（跨学期长期使用）

print("\n[6] 长期使用：第 30 周、循环 6 周")
let week30 = day(2026, 2, 23 + 29 * 7)
if let info = session(SemesterCalculator.phase(startDate: start,
                                               cycleWeeks: 6,
                                               cyclingEnabled: true,
                                               referenceDate: week30),
                      "第 30 周") {
    expectEqual(info.rawWeek, 30, "第 30 周")
    expectEqual(info.displayWeek, (30 - 1) % 6 + 1, "循环 6 周时的显示")
}

// MARK: - 7. 跨夏令时不会算错天数

print("\n[7] 跨夏令时（America/New_York，2026-03-08 调表）")
let newYork = TimeZone(identifier: "America/New_York")!
SemesterCalculator.calendar.timeZone = newYork
let dstStart = day(2026, 3, 1, timeZone: newYork)
let dstAfter = day(2026, 3, 15, timeZone: newYork)
if let info = session(SemesterCalculator.phase(startDate: dstStart,
                                               cycleWeeks: 5,
                                               cyclingEnabled: true,
                                               referenceDate: dstAfter),
                      "跨夏令时") {
    expectEqual(info.daysSinceStart, 14, "跨调表后经过的天数")
    expectEqual(info.rawWeek, 3, "跨调表后的周数")
}
SemesterCalculator.calendar.timeZone = shanghai

// MARK: - 8. 启动弹窗规则

print("\n[8] 启动弹窗规则（1 月 / 7 月 + 首次启动）")

func freshSettings() -> AppSettings {
    let suite = "zhoumu.check.\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suite)!
    defaults.removePersistentDomain(forName: suite)
    return AppSettings(defaults: defaults)
}

// 首次启动：任何月份都弹
for month in [3, 7, 1, 12] {
    let settings = freshSettings()
    expect(settings.setupPromptNeeded(at: day(2026, month, 10)),
           "首次启动（\(month) 月）应弹出设置")
    expect(!settings.hasCompletedFirstLaunch, "首次启动标记初始为未完成")
}

// 普通月份：只弹一次
let march = freshSettings()
march.markSetupPrompted(at: day(2026, 3, 10))
expect(!march.setupPromptNeeded(at: day(2026, 3, 20)), "3 月弹过一次后不再弹出")
expect(!march.setupPromptNeeded(at: day(2026, 4, 1)), "4 月启动不弹出")
expect(!march.setupPromptNeeded(at: day(2026, 6, 30)), "6 月启动不弹出")

// 7 月：进入放假开始月，下次启动弹出
expect(march.setupPromptNeeded(at: day(2026, 7, 1)), "7 月首次启动应弹出设置")
march.markSetupPrompted(at: day(2026, 7, 1))
expect(!march.setupPromptNeeded(at: day(2026, 7, 15)), "7 月内第二次启动不再弹出")
expect(!march.setupPromptNeeded(at: day(2026, 8, 15)), "8 月启动不弹出")

// 次年 1 月：再次弹出
expect(march.setupPromptNeeded(at: day(2027, 1, 2)), "次年 1 月启动应弹出设置")
march.markSetupPrompted(at: day(2027, 1, 2))
expect(!march.setupPromptNeeded(at: day(2027, 1, 20)), "同年 1 月内不再弹出")
expect(march.setupPromptNeeded(at: day(2027, 7, 3)), "次年 7 月再次弹出")

// 首次启动发生在 7 月时，也应记录当月已弹
let july = freshSettings()
expect(july.setupPromptNeeded(at: day(2026, 7, 5)), "首次启动在 7 月应弹出")
july.markSetupPrompted(at: day(2026, 7, 5))
expect(!july.setupPromptNeeded(at: day(2026, 7, 6)), "首次启动弹过后当月不再弹出")
expect(july.setupPromptNeeded(at: day(2027, 1, 4)), "跨到次年 1 月应弹出")

// MARK: - 9. 设置持久化

print("\n[9] 设置持久化")
let suite = "zhoumu.check.persist.\(UUID().uuidString)"
let defaults = UserDefaults(suiteName: suite)!
defaults.removePersistentDomain(forName: suite)
let first = AppSettings(defaults: defaults)
expectEqual(first.cycleWeeks, 3, "默认循环周数")
expect(first.cyclingEnabled, "默认开启循环")
first.startDate = start
first.cycleWeeks = 5
first.cyclingEnabled = false
let reloaded = AppSettings(defaults: defaults)
expectEqual(reloaded.cycleWeeks, 5, "循环周数已持久化")
expect(!reloaded.cyclingEnabled, "循环开关已持久化")
expectEqual(SemesterCalculator.calendar.startOfDay(for: reloaded.startDate),
            SemesterCalculator.calendar.startOfDay(for: start),
            "开学日期已持久化")
reloaded.resetSetupPromptHistory()
expect(reloaded.setupPromptNeeded(at: day(2026, 5, 1)), "重置后下次启动重新弹出")

// MARK: - 10. 课表：星期索引与排索引

print("\n[10] 课表的星期索引与排索引")
expectEqual(SemesterCalculator.dayIndexInWeek(for: day(2026, 9, 14)), 0, "9/14 周一 → 0")
expectEqual(SemesterCalculator.dayIndexInWeek(for: day(2026, 9, 15)), 1, "9/15 周二 → 1")
expectEqual(SemesterCalculator.dayIndexInWeek(for: day(2026, 9, 19)), 5, "9/19 周六 → 5")
expectEqual(SemesterCalculator.dayIndexInWeek(for: day(2026, 9, 20)), 6, "9/20 周日 → 6")

// 开学第 4 周、循环 3 周 → 显示第 1 周 → 用课表第 1 排
if let info = session(SemesterCalculator.phase(startDate: start,
                                               cycleWeeks: 3,
                                               cyclingEnabled: true,
                                               referenceDate: week4),
                      "开学第 4 周") {
    expectEqual(info.displayWeek, 1, "开学第 4 周显示为第 1 周")
    expectEqual(info.scheduleRowIndex, 0, "对应课表第 1 排（索引 0）")
}
if let info = session(SemesterCalculator.phase(startDate: start,
                                               cycleWeeks: 3,
                                               cyclingEnabled: false,
                                               referenceDate: week4),
                      "关闭循环") {
    expectEqual(info.scheduleRowIndex, 0, "关闭循环时固定用课表第 1 排")
}

// MARK: - 11. 课表存取

print("\n[11] 课表存取与持久化")
let scheduleSuite = "zhoumu.check.schedule.\(UUID().uuidString)"
let scheduleDefaults = UserDefaults(suiteName: scheduleSuite)!
scheduleDefaults.removePersistentDomain(forName: scheduleSuite)
let scheduleSettings = AppSettings(defaults: scheduleDefaults)

expect(!scheduleSettings.hasAnySubject, "初始没有课表")
expectEqual(scheduleSettings.scheduleRowCount, 3, "默认循环 3 周 → 课表 3 排")
expectEqual(scheduleSettings.subject(row: 0, day: 0), "", "空格子返回空字符串（= 无）")

scheduleSettings.setSubject("数学", row: 0, day: 0)
scheduleSettings.setSubject("  语文  ", row: 1, day: 2)
expectEqual(scheduleSettings.subject(row: 0, day: 0), "数学", "第 1 排周一 = 数学")
expectEqual(scheduleSettings.subject(row: 1, day: 2), "语文", "首尾空格自动去掉")
expect(scheduleSettings.hasAnySubject, "填过之后 hasAnySubject 为真")

scheduleSettings.setSubject("", row: 0, day: 0)
expectEqual(scheduleSettings.subject(row: 0, day: 0), "", "设为「无」后该格清空")

scheduleSettings.setSubject("   ", row: 4, day: 5)
expectEqual(scheduleSettings.subject(row: 4, day: 5), "", "只有空白也算「无」")

scheduleSettings.setSubject("数学", row: 0, day: 0)
let reloadedSchedule = AppSettings(defaults: scheduleDefaults)
expectEqual(reloadedSchedule.subject(row: 0, day: 0), "数学", "课表已持久化（第 1 排）")
expectEqual(reloadedSchedule.subject(row: 1, day: 2), "语文", "课表已持久化（第 2 排）")

scheduleSettings.cyclingEnabled = false
expectEqual(scheduleSettings.scheduleRowCount, 1, "关闭循环后课表只剩 1 排")

// MARK: - 12. 今天该显示哪一科

print("\n[12] 今天取哪一格的科目")
let todaySuite = "zhoumu.check.today.\(UUID().uuidString)"
let todayDefaults = UserDefaults(suiteName: todaySuite)!
todayDefaults.removePersistentDomain(forName: todaySuite)
let todaySettings = AppSettings(defaults: todayDefaults)

// 2026-09-14 是周一，用它当开学日
let monday = day(2026, 9, 14)
todaySettings.startDate = monday
todaySettings.cycleWeeks = 3
todaySettings.cyclingEnabled = true
todaySettings.setSubject("体育", row: 0, day: 0)   // 第 1 排周一
todaySettings.setSubject("美术", row: 1, day: 0)   // 第 2 排周一

expectEqual(todaySettings.subjectForToday(referenceDate: monday), "体育", "开学当天（周一）取第 1 排周一")
expectEqual(todaySettings.subjectForToday(referenceDate: day(2026, 9, 15)), "", "周二没填 → 无课")
expectEqual(todaySettings.subjectForToday(referenceDate: day(2026, 9, 21)), "美术", "开学第 2 周周一 → 第 2 排")
// 开学第 4 周（差 21 天）按循环又回到第 1 周
expectEqual(todaySettings.subjectForToday(referenceDate: day(2026, 10, 5)), "体育", "开学第 4 周 → 循环回第 1 排")
// 开学前
expectEqual(todaySettings.subjectForToday(referenceDate: day(2026, 9, 7)), "", "开学前不取课表")

// MARK: - 汇总

print("\n----------------------------------------")
if failures == 0 {
    print("全部通过：\(checks) 项检查 ✅")
    exit(0)
} else {
    print("失败 \(failures) / \(checks) 项 ❌")
    exit(1)
}
