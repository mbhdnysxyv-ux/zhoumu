import SwiftUI

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// 外观模式：跟随系统 / 强制浅色 / 强制深色。
enum ThemeMode: String, CaseIterable, Codable, Sendable {
    case system
    case light
    case dark

    var label: String {
        switch self {
        case .system: return "跟随系统"
        case .light:  return "浅色"
        case .dark:   return "深色"
        }
    }
}

extension ThemeMode {
    /// 交给 `preferredColorScheme`；`nil` 表示跟随系统。
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light:  return .light
        case .dark:   return .dark
        }
    }
}

/// v1.3 配色：浅色=白蓝，深色=黑蓝。
///
/// 所有颜色都是「动态色」——同时带浅色和深色两套值，
/// 系统按当前外观自动选，所以 App 和小组件都不用自己判断明暗。
///
/// 注意：macOS 上的离屏渲染工具（Tools/UIRender）没有 UIKit，
/// 这里会退回浅色值，保证工具链照样能编译运行。
enum Palette {

    // MARK: - 主色（蓝）

    /// 主蓝：凸起元素、选中态、圆环进度。
    static let accent = dynamic(light: 0x2563EB, dark: 0x4C8DFF)
    /// 深蓝：小字号文字，保证对比度。
    static let accentDeep = dynamic(light: 0x1D4ED8, dark: 0x86B4FF)
    /// 浅蓝：圆环轨道、未选中的圆点、淡背景块。
    static let accentSoft = dynamic(light: 0xDBEAFE, dark: 0x17253D)
    /// 高亮蓝：用于深色底上的强调文字。
    static let accentBright = dynamic(light: 0x3B82F6, dark: 0x93C0FF)

    // MARK: - 背景与卡片

    /// 底色：浅色是冷白，深色是近黑偏蓝。
    static let background = dynamic(light: 0xF6F9FF, dark: 0x05080F)
    /// 卡片底。
    static let card = dynamic(light: 0xFFFFFF, dark: 0x101827)
    /// 卡片里的次级块（输入框、未选中格）。
    static let cardSoft = dynamic(light: 0xEEF4FF, dark: 0x1A2438)
    /// 分隔线。
    static let line = dynamic(light: 0xDCE7FA, dark: 0x233149)

    // MARK: - 文字

    static let primaryText = dynamic(light: 0x0F1B2D, dark: 0xE8F0FF)
    static let secondaryText = dynamic(light: 0x5A6B85, dark: 0x8296B4)
    /// 最弱的文字：占位符、辅助说明。
    static let faintText = dynamic(light: 0x93A4BE, dark: 0x55688A)

    // MARK: - 语义色

    /// 休息时段（课间）用的绿。
    static let rest = dynamic(light: 0x16A34A, dark: 0x4ADE80)
    /// 警示（未填时间导致胶囊不可用）。
    static let warning = dynamic(light: 0xB45309, dark: 0xFBBF24)

    // MARK: - 工具

    /// 造一个跟随系统外观切换的动态色。
    ///
    /// - iOS（App 与小组件）：用 `UIColor` 的动态构造，跟随系统的深浅色。
    /// - watchOS：`UIColor(dynamicProvider:)` 在这个平台**不可用**，
    ///   而手表界面本来就是深色为主，所以直接取深色那一支。
    /// - macOS（离屏渲染工具）：用 `NSColor` 的动态构造，
    ///   这样 `ImageRenderer` + `.preferredColorScheme(.dark)` 也能渲染出深色版，方便校验配色。
    static func dynamic(light: UInt32, dark: UInt32) -> Color {
        #if os(watchOS)
        return Color(hex: dark)
        #elseif canImport(UIKit)
        return Color(UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(hex: dark)
                : UIColor(hex: light)
        })
        #elseif canImport(AppKit)
        return Color(nsColor: NSColor(name: nil) { appearance in
            let isDark = appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
            return isDark ? NSColor(hex: dark) : NSColor(hex: light)
        })
        #else
        return Color(hex: light)
        #endif
    }
}

// MARK: - 十六进制颜色

extension Color {
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0,
            opacity: 1
        )
    }
}

#if canImport(UIKit)
extension UIColor {
    convenience init(hex: UInt32) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255.0,
            green: CGFloat((hex >> 8) & 0xFF) / 255.0,
            blue: CGFloat(hex & 0xFF) / 255.0,
            alpha: 1
        )
    }
}
#elseif canImport(AppKit)
extension NSColor {
    convenience init(hex: UInt32) {
        self.init(
            srgbRed: CGFloat((hex >> 16) & 0xFF) / 255.0,
            green: CGFloat((hex >> 8) & 0xFF) / 255.0,
            blue: CGFloat(hex & 0xFF) / 255.0,
            alpha: 1
        )
    }
}
#endif
