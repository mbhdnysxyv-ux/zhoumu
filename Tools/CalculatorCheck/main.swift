// 周目计算逻辑的本地校验（不依赖模拟器）。
// 用法：swiftc -O Tools/CalculatorCheck/main.swift ZhouMu/Models/SemesterCalculator.swift ZhouMu/Models/AppSettings.swift -o /tmp/zhoumu-check && /tmp/zhoumu-check
import Combine
import Foundation
import SwiftUI

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

// MARK: - 11. 两张课表：存取、持久化、每日节数、时间

print("\n[11] 课表数据模型")

/// 造一个某天某时刻的 Date。
func at(_ y: Int, _ mo: Int, _ d: Int, _ hh: Int, _ mm: Int) -> Date {
    SemesterCalculator.calendar.date(from: DateComponents(year: y, month: mo, day: d,
                                                          hour: hh, minute: mm))!
}

let scheduleSuite = "zhoumu.check.schedule.\(UUID().uuidString)"
let scheduleDefaults = UserDefaults(suiteName: scheduleSuite)!
scheduleDefaults.removePersistentDomain(forName: scheduleSuite)
let s = AppSettings(defaults: scheduleDefaults)

// 默认状态
expectEqual(s.regular.enabled, false, "默认关闭正课表（老用户不该被一张空表打扰）")
expectEqual(s.evening.enabled, true, "默认启用晚课表")
expectEqual(s.regular.periodCount(day: 0), ScheduleTable.defaultPeriods, "默认每天 8 节")
expectEqual(s.regular.rotatesByWeek, true, "默认按周目轮换")

// 科目读写
s.setSubject("数学", kind: .evening, row: 0, day: 0, period: 0)
s.setSubject("  语文  ", kind: .evening, row: 1, day: 2, period: 1)
expectEqual(s.subject(.evening, row: 0, day: 0, period: 0), "数学", "第 1 排周一第 1 节 = 数学")
expectEqual(s.subject(.evening, row: 1, day: 2, period: 1), "语文", "首尾空格自动去掉")
expect(s.evening.hasAnySubject, "填过之后 hasAnySubject 为真")

s.setSubject("", kind: .evening, row: 0, day: 0, period: 0)
expectEqual(s.subject(.evening, row: 0, day: 0, period: 0), "", "设为「无」后清空")
s.setSubject("   ", kind: .evening, row: 4, day: 5, period: 2)
expectEqual(s.subject(.evening, row: 4, day: 5, period: 2), "", "只有空白也算「无」")

// 两张表互不干扰
s.setSubject("历史", kind: .regular, row: 0, day: 0, period: 0)
expectEqual(s.subject(.regular, row: 0, day: 0, period: 0), "历史", "正课表独立存储")
expectEqual(s.subject(.evening, row: 0, day: 0, period: 0), "", "晚课表不受正课表影响")

// 持久化往返
s.setSubject("数学", kind: .evening, row: 0, day: 0, period: 0)
let reloadedSchedule = AppSettings(defaults: scheduleDefaults)
expectEqual(reloadedSchedule.subject(.evening, row: 0, day: 0, period: 0), "数学", "晚课表已持久化")
expectEqual(reloadedSchedule.subject(.regular, row: 0, day: 0, period: 0), "历史", "正课表已持久化")

// 排数：轮换 vs 固定
expectEqual(s.evening.rowCount(cycleWeeks: 3), 3, "轮换时 3 排")
var fixedTable = s.regular
fixedTable.rotatesByWeek = false
expectEqual(fixedTable.rowCount(cycleWeeks: 3), 1, "固定时只有 1 排")
expectEqual(fixedTable.rowCount(cycleWeeks: 20), 1, "固定时排数不随循环周数变")

// 每日节数独立可调 + 上下限夹紧
var perDay = ScheduleTable.empty()
perDay.periodsPerDay = [1, 2, 3, 4, 5, 6, 7]
perDay.normalize()
expectEqual(perDay.periodCount(day: 0), 1, "周一 1 节")
expectEqual(perDay.periodCount(day: 6), 7, "周日 7 节")
perDay.periodsPerDay = [99, 0, 3, 3, 3, 3, 3]
perDay.normalize()
expectEqual(perDay.periodCount(day: 0), ScheduleTable.maxPeriods, "节数上限夹到 12")
expectEqual(perDay.periodCount(day: 1), ScheduleTable.minPeriods, "节数下限夹到 1")

// 时间可选 + 合法性
expect(!s.evening.hasAnyTime, "没填过时间 → hasAnyTime 为假")
var timed = ScheduleTable.empty()
timed.periodTimes = [PeriodTime(start: 8 * 60, end: 8 * 60 + 45),
                     nil,
                     PeriodTime(start: 10 * 60, end: 9 * 60)]
timed.normalize()
expect(timed.hasAnyTime, "填了一节合法时间 → hasAnyTime 为真")
expectEqual(timed.time(forPeriod: 1) == nil, true, "nil 的那节取不到时间")
expectEqual(timed.time(forPeriod: 2) == nil, true, "end <= start 的非法时间被忽略")

// MARK: - 12. 两张表合并成时间轴 + 状态机

print("\n[12] 时间轴合并与状态机")

// 2026-09-14 是周一
let mondayDate = day(2026, 9, 14)
let mondayNoon = at(2026, 9, 14, 12, 0)

var reg = ScheduleTable(enabled: true, rotatesByWeek: false,
                        periodsPerDay: [3, 3, 3, 3, 3, 0, 0],
                        periodTimes: [PeriodTime(start: 8 * 60, end: 8 * 60 + 45),
                                      PeriodTime(start: 9 * 60, end: 9 * 60 + 45),
                                      PeriodTime(start: 10 * 60, end: 10 * 60 + 45)],
                        subjects: [:])
reg.setSubject("数学", row: 0, day: 0, period: 0)
reg.setSubject("语文", row: 0, day: 0, period: 1)
reg.setSubject("英语", row: 0, day: 0, period: 2)

var eve = ScheduleTable(enabled: true, rotatesByWeek: true,
                        periodsPerDay: Array(repeating: 1, count: 7),
                        periodTimes: [PeriodTime(start: 19 * 60, end: 20 * 60)],
                        subjects: [:])
eve.setSubject("晚自习", row: 0, day: 0, period: 0)
eve.setSubject("晚自习二号", row: 1, day: 0, period: 0)

let merged = ClassSchedule.classes(for: mondayDate,
                                   tables: [.regular: reg, .evening: eve],
                                   displayWeek: 1)
expectEqual(merged.count, 4, "正课 3 节 + 晚课 1 节 = 4 节")
expectEqual(merged.first?.subject, "数学", "第一节课是数学")
expectEqual(merged.last?.subject, "晚自习", "最后一节是晚自习（时间最晚）")
expect(merged[0].start < merged[1].start, "按时间升序排列")

// 固定表在任意周目都取第 0 排
let mergedWeek3 = ClassSchedule.classes(for: mondayDate,
                                        tables: [.regular: reg, .evening: eve],
                                        displayWeek: 3)
expectEqual(mergedWeek3.filter { $0.kind == .regular }.count, 3, "固定表在第 3 周目仍有 3 节正课")
expectEqual(mergedWeek3.filter { $0.kind == .regular }.first?.subject, "数学", "固定表不随周目变")
// 轮换表：第 2 周目取第 2 排（填了「晚自习二号」），第 3 排没填所以第 3 周目无晚课
let mergedWeek2 = ClassSchedule.classes(for: mondayDate,
                                        tables: [.regular: reg, .evening: eve],
                                        displayWeek: 2)
expectEqual(mergedWeek2.filter { $0.kind == .evening }.first?.subject, "晚自习二号",
            "轮换表第 2 周目取第 2 排")
expectEqual(mergedWeek3.filter { $0.kind == .evening }.count, 0,
            "轮换表第 3 周目取第 3 排（那排没填 → 无晚课）")

// 关闭某张表就不参与合并
var eveOff = eve
eveOff.enabled = false
let mergedOff = ClassSchedule.classes(for: mondayDate,
                                      tables: [.regular: reg, .evening: eveOff],
                                      displayWeek: 1)
expectEqual(mergedOff.count, 3, "关闭晚课表后只剩 3 节")
expectEqual(mergedOff.filter { $0.kind == .evening }.count, 0, "关闭的表完全不出现")

// 状态机
let stateBefore = ClassSchedule.state(at: at(2026, 9, 14, 7, 0), classes: merged)
if case .beforeSchool(let next) = stateBefore {
    expectEqual(next.subject, "数学", "7:00 还没上课，下一节是数学")
} else {
    expect(false, "7:00 应该是 beforeSchool")
}

let stateIn = ClassSchedule.state(at: at(2026, 9, 14, 8, 20), classes: merged)
if case .inClass(let cur, let nxt) = stateIn {
    expectEqual(cur.subject, "数学", "8:20 正在上数学")
    expectEqual(nxt?.subject, "语文", "下一节是语文")
} else {
    expect(false, "8:20 应该是 inClass")
}
expectEqual(stateIn.ringProgress(at: at(2026, 9, 14, 8, 20)), 20.0 / 45.0, "环进度 = 20/45")

let stateRest = ClassSchedule.state(at: at(2026, 9, 14, 8, 50), classes: merged)
if case .resting(let ended, let next) = stateRest {
    expectEqual(ended.subject, "数学", "课间：刚结束的是数学")
    expectEqual(next.subject, "语文", "课间：下一节是语文")
} else {
    expect(false, "8:50 应该是课间")
}
expectEqual(stateRest.ringProgress(at: at(2026, 9, 14, 8, 50)), 1.0, "课间环闭合（=1）")

let stateDone = ClassSchedule.state(at: at(2026, 9, 14, 21, 0), classes: merged)
if case .finished(let last) = stateDone {
    expectEqual(last.subject, "晚自习", "21:00 全部上完，最后一节是晚自习")
} else {
    expect(false, "21:00 应该是 finished")
}
expectEqual(stateDone.ringProgress(at: at(2026, 9, 14, 21, 0)), 1.0, "完课后环闭合")

// MARK: - 13. 圈内容：有时间轴 vs 没时间回退晚课

print("\n[13] 首页圈内容")

// 有时间轴：上课中显示当前科目
let contentIn = ClassSchedule.ringContent(at: at(2026, 9, 14, 8, 20),
                                          tables: [.regular: reg, .evening: eve],
                                          displayWeek: 1)
expectEqual(contentIn.subject, "数学", "上课中圈内显示当前科目")
expectEqual(contentIn.caption, "周一", "上课中圈内小字是周几")
expect(contentIn.countdown.untilCurrentEnd != nil, "上课中「这节还剩」有值")
expectEqual(contentIn.countdown.nextSubject, "语文", "「下节」是语文")
expectEqual(Int(contentIn.countdown.untilCurrentEnd ?? 0), 25 * 60, "距下课 25 分钟")

// 没时间轴：回退到当日晚课
// 注意：必须【两张表都没时间】才算「排不出时间轴」，所以这里把正课表也关掉。
var eveNoTime = eve
eveNoTime.periodTimes = [nil]
var regOffForFallback = reg
regOffForFallback.enabled = false
let fallback = ClassSchedule.ringContent(at: mondayNoon,
                                         tables: [.regular: regOffForFallback, .evening: eveNoTime],
                                         displayWeek: 1)
expectEqual(fallback.subject, "晚自习", "没填时间 → 圈内显示当天晚课表的科目")
expectEqual(fallback.caption, "当日晚课", "没填时间 → 小字标「当日晚课」")
expectEqual(fallback.progress, 0.0, "没填时间 → 环不填充")
expect(fallback.countdown.isEmpty, "没填时间 → 三行倒计时全空")

// 晚课表也关了 → 无课
var eveOff2 = eveNoTime
eveOff2.enabled = false
let noClass = ClassSchedule.ringContent(at: mondayNoon,
                                        tables: [.regular: regOffForFallback, .evening: eveOff2],
                                        displayWeek: 1)
expectEqual(noClass.subject, "无课", "两张表都没得用 → 无课")

// MARK: - 14. v1.2 → v1.3 迁移

print("\n[14] 旧课表迁移")

let legacy = ["0-0": "体育", "1-2": "美术", "2-6": "音乐"]
if let migrated = ScheduleMigration.eveningTable(fromLegacy: legacy) {
    expectEqual(migrated.enabled, true, "迁移后的晚课表默认启用")
    expectEqual(migrated.rotatesByWeek, true, "v1.2 课表本来就是轮换的")
    expectEqual(migrated.periodCount(day: 0), 1, "迁移后每天 1 节")
    expectEqual(migrated.subject(row: 0, day: 0, period: 0), "体育", "第 1 排周一迁移正确")
    expectEqual(migrated.subject(row: 1, day: 2, period: 0), "美术", "第 2 排周三迁移正确")
    expectEqual(migrated.subject(row: 2, day: 6, period: 0), "音乐", "第 3 排周日迁移正确")
    expect(!migrated.hasAnyTime, "迁移后没有时间（灵动岛不可用，符合预期）")
} else {
    expect(false, "迁移不该返回 nil")
}
expectEqual(ScheduleMigration.eveningTable(fromLegacy: [:]) == nil, true, "空课表不迁移")

// 端到端：旧数据写进 defaults，AppSettings 应自动迁到晚课表
let legacySuite = "zhoumu.check.legacy.\(UUID().uuidString)"
let legacyDefaults = UserDefaults(suiteName: legacySuite)!
legacyDefaults.removePersistentDomain(forName: legacySuite)
legacyDefaults.set(Date(timeIntervalSince1970: 1_700_000_000), forKey: SharedStorage.Key.startDate)
legacyDefaults.set(legacy, forKey: SharedStorage.Key.legacySchedule)
let migratedSettings = AppSettings(defaults: legacyDefaults)
expectEqual(migratedSettings.evening.subject(row: 0, day: 0, period: 0), "体育",
            "AppSettings 启动时自动把旧课表迁进晚课表")
expectEqual(migratedSettings.regular.hasAnySubject, false, "迁移只影响晚课表")

// MARK: - 15. 主题模式

print("\n[15] 主题模式")

let themeSuite = "zhoumu.check.theme.\(UUID().uuidString)"
let themeDefaults = UserDefaults(suiteName: themeSuite)!
themeDefaults.removePersistentDomain(forName: themeSuite)
let themeSettings = AppSettings(defaults: themeDefaults)
expectEqual(themeSettings.themeMode, ThemeMode.system, "默认跟随系统")
themeSettings.themeMode = .dark
let reloadedTheme = AppSettings(defaults: themeDefaults)
expectEqual(reloadedTheme.themeMode, ThemeMode.dark, "主题模式已持久化")
expectEqual(ThemeMode.allCases.count, 3, "三态：跟随系统 / 浅色 / 深色")
expectEqual(ThemeMode.system.colorScheme == nil, true, "跟随系统时 preferredColorScheme 传 nil")
expectEqual(ThemeMode.light.colorScheme, ColorScheme.light, "浅色映射正确")
expectEqual(ThemeMode.dark.colorScheme, ColorScheme.dark, "深色映射正确")

// MARK: - 汇总

print("\n----------------------------------------")
if failures == 0 {
    print("全部通过：\(checks) 项检查 ✅")
    exit(0)
} else {
    print("失败 \(failures) / \(checks) 项 ❌")
    exit(1)
}
