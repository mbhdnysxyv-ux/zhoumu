// 用 SwiftUI 的 ImageRenderer 把界面渲染成 PNG，便于在没有模拟器运行时的情况下检查排版。
// 由 Tools/render_ui.sh 调用。
import AppKit
import Foundation
import SwiftUI

let outputDirectory = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "build/UIHarness/out"

func day(offsetFromToday days: Int) -> Date {
    let calendar = Calendar.current
    let today = calendar.startOfDay(for: Date())
    return calendar.date(byAdding: .day, value: days, to: today)!
}

/// 造一张「现在正在上课」的课表：第 1 节从 10 分钟前开始，第 2、3 节往后排。
/// 这样无论什么时候跑渲染，都能稳定拿到 inClass 状态。
func sampleRegular(kind: ScheduleKind = .regular) -> ScheduleTable {
    let cal = SemesterCalculator.calendar
    let now = Date()
    let minutesNow = cal.dateComponents([.hour, .minute], from: now)
    let base = (minutesNow.hour ?? 8) * 60 + (minutesNow.minute ?? 0) - 10

    var table = ScheduleTable(enabled: true,
                              rotatesByWeek: false,
                              periodsPerDay: [3, 3, 3, 3, 3, 0, 0],
                              periodTimes: [PeriodTime(start: base, end: base + 45),
                                            PeriodTime(start: base + 60, end: base + 105),
                                            PeriodTime(start: base + 120, end: base + 165)],
                              subjects: [:])
    let today = SemesterCalculator.dayIndexInWeek(for: now)
    table.setSubject("数学", row: 0, day: today, period: 0)
    table.setSubject("语文", row: 0, day: today, period: 1)
    table.setSubject("英语", row: 0, day: today, period: 2)
    // 其余日子也填一点，方便看整体
    for d in 0..<5 where d != today {
        table.setSubject("物理", row: 0, day: d, period: 0)
        table.setSubject("化学", row: 0, day: d, period: 1)
        table.setSubject("生物", row: 0, day: d, period: 2)
    }
    _ = kind
    return table
}

/// 晚课表：轮换 3 排，每天 1 节，晚上 19:00–20:30。
func sampleEvening() -> ScheduleTable {
    var table = ScheduleTable(enabled: true,
                              rotatesByWeek: true,
                              periodsPerDay: Array(repeating: 1, count: 7),
                              periodTimes: [PeriodTime(start: 19 * 60, end: 20 * 60 + 30)],
                              subjects: [:])
    let today = SemesterCalculator.dayIndexInWeek(for: Date())
    table.setSubject("晚自习", row: 0, day: today, period: 0)
    table.setSubject("晚自习", row: 1, day: today, period: 0)
    table.setSubject("晚自习", row: 2, day: today, period: 0)
    table.setSubject("周会", row: 0, day: (today + 2) % 7, period: 0)
    return table
}

/// 没填任何时间的晚课表——用来验证「回退显示当日晚课」。
func sampleEveningNoTime() -> ScheduleTable {
    var table = ScheduleTable(enabled: true,
                              rotatesByWeek: true,
                              periodsPerDay: Array(repeating: 1, count: 7),
                              periodTimes: [nil],
                              subjects: [:])
    let today = SemesterCalculator.dayIndexInWeek(for: Date())
    table.setSubject("晚自习", row: 0, day: today, period: 0)
    return table
}

func makeSettings(startOffset: Int,
                  cycle: Int,
                  enabled: Bool,
                  regular: ScheduleTable? = nil,
                  evening: ScheduleTable? = nil,
                  theme: ThemeMode = .light) -> AppSettings {
    let suite = "zhoumu.render.\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suite)!
    defaults.removePersistentDomain(forName: suite)
    let settings = AppSettings(defaults: defaults)
    settings.startDate = day(offsetFromToday: startOffset)
    settings.cycleWeeks = cycle
    settings.cyclingEnabled = enabled
    settings.themeMode = theme
    if let regular { settings.regular = regular }
    if let evening { settings.evening = evening }
    settings.markSetupPrompted(at: day(offsetFromToday: -1))
    return settings
}

@MainActor
func render(_ view: some View, name: String, dark: Bool = false, size: CGSize = CGSize(width: 393, height: 852)) {
    let renderer = ImageRenderer(content: view
        .frame(width: size.width, height: size.height)
        .background(Palette.background)
        .preferredColorScheme(dark ? .dark : .light))
    renderer.scale = 2

    // 关键：ImageRenderer 不跟随 `.preferredColorScheme`，
    // 动态色（NSColor 的 dynamicProvider）是按当前 NSAppearance 解析的，
    // 所以要把绘制过程放进对应的 appearance 里。
    // 关键：ImageRenderer 不跟随 `.preferredColorScheme`。
    // 动态色（NSColor 的 dynamicProvider）按【当前 NSAppearance】解析，
    // 而 `renderer.nsImage` 是懒加载的——绘制发生在首次访问时，
    // 所以必须把「取图 + 编码」整段都放进 appearance 作用域里。
    var png: Data?
    let work = {
        guard let image = renderer.nsImage,
              let tiff = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiff) else { return }
        png = bitmap.representation(using: .png, properties: [:])
    }
    if let appearance = NSAppearance(named: dark ? .darkAqua : .aqua) {
        appearance.performAsCurrentDrawingAppearance { work() }
    } else {
        work()
    }

    guard let png else {
        print("✗ 渲染失败：\(name)")
        return
    }

    let directory = URL(fileURLWithPath: outputDirectory)
    try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    do {
        try png.write(to: directory.appendingPathComponent(name))
        print("✓ \(name)")
    } catch {
        print("✗ 写入 \(name) 失败：\(error)")
    }
}

@MainActor
func renderAll() {
    let regular = sampleRegular()
    let evening = sampleEvening()

    // 1. 第一页：正在上课 → 圈内当前科目、三行倒计时都有值（环按本节进度）
    render(HomeView().environmentObject(makeSettings(startOffset: -21, cycle: 3, enabled: true,
                                                     regular: regular, evening: evening)),
           name: "01-home-in-class.png")

    // 2. 第一页 · 深色模式（黑蓝配色）
    render(HomeView().environmentObject(makeSettings(startOffset: -21, cycle: 3, enabled: true,
                                                     regular: regular, evening: evening,
                                                     theme: .dark)),
           name: "02-home-dark.png", dark: true)

    // 3. 没填任何时间 → 圈内回退显示当日晚课，三行倒计时为空
    render(HomeView().environmentObject(makeSettings(startOffset: -21, cycle: 3, enabled: true,
                                                     regular: nil, evening: sampleEveningNoTime())),
           name: "03-home-no-times.png")

    // 4. 还没开学
    render(HomeView().environmentObject(makeSettings(startOffset: 5, cycle: 3, enabled: true,
                                                     regular: regular, evening: evening)),
           name: "04-home-not-started.png")

    // 5. 第二页：当日完整课表
    render(TodayScheduleView(now: Date())
        .environmentObject(makeSettings(startOffset: -21, cycle: 3, enabled: true,
                                        regular: regular, evening: evening))
        .padding(.horizontal, 22),
           name: "05-today-schedule.png")

    // 6. 设置页
    render(SettingsView().environmentObject(makeSettings(startOffset: -21, cycle: 3, enabled: true,
                                                         regular: regular, evening: evening)),
           name: "06-settings.png")

    // 7. 设置页 · 深色
    render(SettingsView().environmentObject(makeSettings(startOffset: -21, cycle: 3, enabled: true,
                                                         regular: regular, evening: evening,
                                                         theme: .dark)),
           name: "07-settings-dark.png", dark: true)

    // 8. 课表编辑器
    render(ScheduleEditorView(kind: .regular)
        .environmentObject(makeSettings(startOffset: -21, cycle: 3, enabled: true,
                                        regular: regular, evening: evening))
        .padding(.horizontal, 0),
           name: "08-schedule-editor.png", size: CGSize(width: 393, height: 1000))
}

/// 直接解析调色板在两套外观下的实际 RGB。
///
/// 离屏渲染工具没法真的切到深色外观（ImageRenderer 不跟随 colorScheme），
/// 所以深色配色靠这里做数值校验，而不是靠截图。
@MainActor
func dumpPalette() {
    print("\n--- 调色板实际取值 ---")
    let items: [(String, Color)] = [
        ("accent", Palette.accent),
        ("accentDeep", Palette.accentDeep),
        ("accentSoft", Palette.accentSoft),
        ("background", Palette.background),
        ("card", Palette.card),
        ("primaryText", Palette.primaryText),
        ("secondaryText", Palette.secondaryText),
    ]
    for (label, appearanceName) in [("浅色", NSAppearance.Name.aqua), ("深色", .darkAqua)] {
        guard let appearance = NSAppearance(named: appearanceName) else { continue }
        var line = "  \(label): "
        appearance.performAsCurrentDrawingAppearance {
            for (name, color) in items {
                let ns = NSColor(color).usingColorSpace(.sRGB)
                let hex = ns.map { String(format: "%02X%02X%02X",
                                          Int($0.redComponent * 255),
                                          Int($0.greenComponent * 255),
                                          Int($0.blueComponent * 255)) } ?? "?"
                line += "\(name)=#\(hex) "
            }
        }
        print(line)
    }
}

MainActor.assumeIsolated {
    dumpPalette()
    renderAll()
}
