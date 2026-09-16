// 生成 App 图标（1024×1024 PNG，橙白配色）。
// 用法：swift Tools/make_icon.swift <输出路径>
import CoreGraphics
import CoreText
import Foundation
import ImageIO

let side = 1024
let center = CGPoint(x: side / 2, y: side / 2)

func rgb(_ r: Double, _ g: Double, _ b: Double) -> CGColor {
    CGColor(srgbRed: r, green: g, blue: b, alpha: 1)
}

let outputPath = CommandLine.arguments.count > 1
    ? CommandLine.arguments[1]
    : "AppIcon-1024.png"

guard let context = CGContext(data: nil,
                              width: side,
                              height: side,
                              bitsPerComponent: 8,
                              bytesPerRow: 0,
                              space: CGColorSpaceCreateDeviceRGB(),
                              bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue) else {
    fatalError("无法创建绘图上下文")
}

// 暖白底
context.setFillColor(rgb(1.0, 0.976, 0.957))
context.fill(CGRect(x: 0, y: 0, width: side, height: side))

// 循环轨道
let ringInset: CGFloat = 148
context.setStrokeColor(rgb(1.0, 0.898, 0.804))
context.setLineWidth(66)
context.strokeEllipse(in: CGRect(x: ringInset,
                                 y: ringInset,
                                 width: CGFloat(side) - ringInset * 2,
                                 height: CGFloat(side) - ringInset * 2))

// 循环进度：走满 5/7
let radius = (CGFloat(side) - ringInset * 2) / 2
context.setStrokeColor(rgb(0.980, 0.451, 0.090))
context.setLineWidth(66)
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
    kCTForegroundColorAttributeName: rgb(0.980, 0.451, 0.090),
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
print("已生成图标：\(outputPath)")
