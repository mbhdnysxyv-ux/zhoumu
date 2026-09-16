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

func makeSettings(startOffset: Int, cycle: Int, enabled: Bool, schedule: [String: String] = [:]) -> AppSettings {
    let suite = "zhoumu.render.\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suite)!
    defaults.removePersistentDomain(forName: suite)
    let settings = AppSettings(defaults: defaults)
    settings.startDate = day(offsetFromToday: startOffset)
    settings.cycleWeeks = cycle
    settings.cyclingEnabled = enabled
    settings.schedule = schedule
    // 标记已完成引导，避免渲染时弹出设置页。
    settings.markSetupPrompted(at: day(offsetFromToday: -1))
    return settings
}

/// 一份示例课表：三排（对应循环 3 周），并且保证「今天」那一格有科目。
func sampleSchedule() -> [String: String] {
    let todayDay = SemesterCalculator.dayIndexInWeek(for: Date())
    var schedule: [String: String] = [
        "0-0": "数学", "0-1": "语文", "0-2": "英语", "0-3": "物理", "0-4": "化学",
        "1-0": "历史", "1-2": "地理", "1-4": "政治", "1-6": "体育",
        "2-1": "生物", "2-3": "美术", "2-5": "音乐",
    ]
    schedule["0-\(todayDay)"] = "数学"
    return schedule
}

@MainActor
func render(_ view: some View, name: String) {
    let size = CGSize(width: 393, height: 852) // iPhone 15/16 逻辑分辨率
    let renderer = ImageRenderer(content: view
        .frame(width: size.width, height: size.height)
        .background(Palette.background)
        .preferredColorScheme(.light))
    renderer.scale = 2

    guard let image = renderer.nsImage,
          let tiff = image.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiff),
          let png = bitmap.representation(using: .png, properties: [:]) else {
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
    // 1. 开学第 4 周 + 循环 3 周 + 有课表 → 圈内显示今天的科目，圈下显示「第 1 周」
    render(HomeView().environmentObject(makeSettings(startOffset: -21, cycle: 3, enabled: true,
                                                     schedule: sampleSchedule())),
           name: "01-home-cycle-3weeks.png")

    // 2. 关闭循环 → 圈下应显示「第 4 周」
    render(HomeView().environmentObject(makeSettings(startOffset: -21, cycle: 3, enabled: false,
                                                     schedule: sampleSchedule())),
           name: "02-home-no-cycle.png")

    // 3. 还没开学 → 应显示「未开学 还有 5 天」
    render(HomeView().environmentObject(makeSettings(startOffset: 5, cycle: 3, enabled: true)),
           name: "03-home-not-started.png")

    // 4. 循环 6 周、开学第 12 周 → 显示第 6 周
    render(HomeView().environmentObject(makeSettings(startOffset: -77, cycle: 6, enabled: true,
                                                     schedule: sampleSchedule())),
           name: "04-home-cycle-6weeks.png")

    // 5. 课表里今天那格是「无」→ 圈内显示「无课」
    var emptyToday = sampleSchedule()
    emptyToday.removeValue(forKey: "0-\(SemesterCalculator.dayIndexInWeek(for: Date()))")
    render(HomeView().environmentObject(makeSettings(startOffset: -21, cycle: 3, enabled: true,
                                                     schedule: emptyToday)),
           name: "05-home-no-subject-today.png")

    // 6. 设置页（含课表网格）
    render(SettingsView().environmentObject(makeSettings(startOffset: -21, cycle: 3, enabled: true,
                                                         schedule: sampleSchedule())),
           name: "06-settings.png")
}

MainActor.assumeIsolated {
    renderAll()
}
