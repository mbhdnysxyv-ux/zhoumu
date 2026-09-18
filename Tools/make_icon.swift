// 生成 App 图标（1024×1024 PNG）。
//
// 用法：
//   swift Tools/make_icon.swift <输出路径> [light|dark]
//
// v1.3 起配色跟着 App 走：
//   light = 白蓝（#F6F9FF 底 + #2563EB 蓝）
//   dark  = 黑蓝（#05080F 底 + #4C8DFF 蓝）
import CoreGraphics
import CoreText
import Foundation
import ImageIO

let side = 1024
let center = CGPoint(x: side / 2, y: side / 2)

func rgb(_ hex: UInt32) -> CGColor {
    CGColor(srgbRed: CGFloat((hex >> 16) & 0xFF) / 255.0,
            green: CGFloat((hex >> 8) & 0xFF) / 255.0,
            blue: CGFloat(hex & 0xFF) / 255.0,
            alpha: 1)
}

let outputPath = CommandLine.arguments.count > 1
    ? CommandLine.arguments[1]
    : "AppIcon-1024.png"
let isDark = CommandLine.arguments.count > 2 && CommandLine.arguments[2] == "dark"

// 和 Shared/Theme.swift 里的 Palette 保持一致
let backgroundHex: UInt32 = isDark ? 0x05080F : 0xF6F9FF
let trackHex:      UInt32 = isDark ? 0x17253D : 0xDBEAFE
let accentHex:     UInt32 = isDark ? 0x4C8DFF : 0x2563EB

/// 深色图标加一层很淡的中心光晕，避免整体发闷。
///
/// 用**离散同心圆**而不是 CGGradient：平滑渐变会产生上千种中间色，
/// PNG 直接涨到 550KB；离散画法只有十几个颜色，压到 50KB 级别，观感几乎一样
/// （图标实际显示尺寸才 60–180px，阶梯根本看不出来）。
func drawCenterGlow(_ context: CGContext) {
    guard isDark else { return }
    let steps = 16
    let maxRadius = CGFloat(side) * 0.62
    for i in stride(from: steps, through: 1, by: -1) {
        let t = CGFloat(i) / CGFloat(steps)          // 1 → 0
        let radius = maxRadius * t
        let alpha = 0.022 * (1 - t) + 0.012           // 中心最亮，向外递减
        context.setFillColor(rgb(0x4C8DFF).copy(alpha: alpha)!)
        context.fillEllipse(in: CGRect(x: center.x - radius,
                                       y: center.y - radius,
                                       width: radius * 2,
                                       height: radius * 2))
    }
}

guard let context = CGContext(data: nil,
                              width: side,
                              height: side,
                              bitsPerComponent: 8,
                              bytesPerRow: 0,
                              space: CGColorSpaceCreateDeviceRGB(),
                              bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue) else {
    fatalError("无法创建绘图上下文")
}

// 底
context.setFillColor(rgb(backgroundHex))
context.fill(CGRect(x: 0, y: 0, width: side, height: side))
drawCenterGlow(context)

// 循环轨道
let ringInset: CGFloat = 148
let ringWidth: CGFloat = isDark ? 62 : 66
context.setStrokeColor(rgb(trackHex))
context.setLineWidth(ringWidth)
context.strokeEllipse(in: CGRect(x: ringInset,
                                 y: ringInset,
                                 width: CGFloat(side) - ringInset * 2,
                                 height: CGFloat(side) - ringInset * 2))

// 循环进度：走满 5/7（和首页第一周周五的观感一致）
let radius = (CGFloat(side) - ringInset * 2) / 2
context.setStrokeColor(rgb(accentHex))
context.setLineWidth(ringWidth)
context.setLineCap(.round)
context.addArc(center: center,
               radius: radius,
               startAngle: -.pi / 2,
               endAngle: -.pi / 2 + 2 * .pi * (5.0 / 7.0),
               clockwise: false)
context.strokePath()

// 中间的「周」字
let font = CTFontCreateWithName("PingFangSC-Semibold" as CFString, 330, nil)
let attributes: [CFString: Any] = [
    kCTFontAttributeName: font,
    kCTForegroundColorAttributeName: rgb(accentHex),
]
guard let attributed = CFAttributedStringCreate(nil, "周" as CFString, attributes as CFDictionary) else {
    fatalError("无法创建文本")
}
let line = CTLineCreateWithAttributedString(attributed)
let bounds = CTLineGetBoundsWithOptions(line, .useOpticalBounds)
context.textPosition = CGPoint(x: center.x - bounds.width / 2 - bounds.origin.x,
                               y: center.y - bounds.height / 2 - bounds.origin.y)
CTLineDraw(line, context)

guard let image = context.makeImage() else { fatalError("无法生成图片") }
let url = URL(fileURLWithPath: outputPath)
guard let destination = CGImageDestinationCreateWithURL(url as CFURL,
                                                       "public.png" as CFString,
                                                       1,
                                                       nil) else {
    fatalError("无法写入 \(outputPath)")
}
CGImageDestinationAddImage(destination, image, nil)
guard CGImageDestinationFinalize(destination) else { fatalError("写入失败") }
print("已生成图标（\(isDark ? "深色" : "浅色")）：\(outputPath)")
