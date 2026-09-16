// 用 ImageRenderer 渲染小组件界面，便于在没有真机/模拟器桌面操作的情况下检查排版。
// 由 Tools/render_widget.sh 调用。
import AppKit
import SwiftUI
import WidgetKit

let outputDirectory = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "build/WidgetRender/out"

/// macOS 上 \.widgetFamily 只读，渲染时用这个全局量代替（由脚本改写小组件源码注入）。
enum RenderFamily {
    static var current: WidgetFamily = .systemSmall
}

func day(offset: Int) -> Date {
    let calendar = Calendar.current
    let today = calendar.startOfDay(for: Date())
    return calendar.date(byAdding: .day, value: offset, to: today)!
}

@MainActor
func render(_ view: some View, size: CGSize, name: String) {
    let renderer = ImageRenderer(content: view
        .padding(16)                     // 模拟真机上 WidgetKit 自动加的内容边距
        .frame(width: size.width, height: size.height)
        .background(Palette.background)
        .preferredColorScheme(.light))
    renderer.scale = 3

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

let small = CGSize(width: 170, height: 170)
let medium = CGSize(width: 364, height: 170)

@MainActor
func renderAll() {
    // 开学第 4 周 + 循环 3 周 → 显示第 1 周
    let phase = SemesterCalculator.phase(startDate: day(offset: -21),
                                         cycleWeeks: 3,
                                         cyclingEnabled: true)

    let withClass = WeekEntry(date: Date(), phase: phase, subject: "数学", isFromApp: true)
    let noClass = WeekEntry(date: Date(), phase: phase, subject: "", isFromApp: true)

    RenderFamily.current = .systemSmall
    render(WeekWidgetEntryView(entry: withClass), size: small, name: "01-small-subject.png")
    render(WeekWidgetEntryView(entry: noClass), size: small, name: "02-small-noclass.png")

    RenderFamily.current = .systemMedium
    render(WeekWidgetEntryView(entry: withClass), size: medium, name: "03-medium-subject.png")
    render(WeekWidgetEntryView(entry: noClass), size: medium, name: "04-medium-noclass.png")

    // 还没在 App 里设置过开学日期
    RenderFamily.current = .systemSmall
    render(WeekWidgetEntryView(entry: WeekEntry(date: Date(), phase: nil, subject: "", isFromApp: true)),
           size: small, name: "05-small-unset.png")

    // 还没开学
    let notStarted = SemesterCalculator.phase(startDate: day(offset: 5),
                                              cycleWeeks: 3,
                                              cyclingEnabled: true)
    render(WeekWidgetEntryView(entry: WeekEntry(date: Date(), phase: notStarted, subject: "", isFromApp: true)),
           size: small, name: "06-small-not-started.png")

    // 回退模式（自签安装、App Group 权限被丢掉）：只显示周目，不显示科目
    render(WeekWidgetEntryView(entry: WeekEntry(date: Date(), phase: phase, subject: "", isFromApp: false)),
           size: small, name: "07-small-fallback.png")
}

MainActor.assumeIsolated {
    renderAll()
}
