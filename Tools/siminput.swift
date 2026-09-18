// 给 iOS 模拟器发鼠标事件。System Events 的 `click at` 只能点不能拖，
// 截图流程里要翻页/滑动，所以直接用 CGEvent 发。
//
// 用法（屏幕坐标）：
//   swift Tools/siminput.swift tap  <x> <y>
//   swift Tools/siminput.swift drag <x1> <y1> <x2> <y2> [步数]
import CoreGraphics
import Foundation

func pt(_ x: Double, _ y: Double) -> CGPoint { CGPoint(x: x, y: y) }

func post(_ type: CGEventType, _ p: CGPoint, _ button: CGMouseButton = .left) {
    CGEvent(mouseEventSource: nil, mouseType: type, mouseCursorPosition: p, mouseButton: button)?
        .post(tap: .cghidEventTap)
    usleep(16_000)
}

func move(_ p: CGPoint) {
    post(.mouseMoved, p)
}

let a = CommandLine.arguments
guard a.count >= 4 else {
    FileHandle.standardError.write("用法: siminput tap x y | siminput drag x1 y1 x2 y2 [步骤]\n".data(using: .utf8)!)
    exit(2)
}

switch a[1] {
case "tap":
    guard let x = Double(a[2]), let y = Double(a[3]) else { exit(2) }
    let p = pt(x, y)
    move(p)
    usleep(90_000)
    post(.leftMouseDown, p)
    usleep(70_000)
    post(.leftMouseUp, p)
    print("tap (\(Int(x)), \(Int(y)))")

case "drag":
    guard a.count >= 6, let x1 = Double(a[2]), let y1 = Double(a[3]),
          let x2 = Double(a[4]), let y2 = Double(a[5]) else { exit(2) }
    let steps = a.count > 6 ? (Int(a[6]) ?? 30) : 30
    let from = pt(x1, y1), to = pt(x2, y2)
    move(from)
    usleep(140_000)
    post(.leftMouseDown, from)
    // 前 1/4 慢慢起步，模拟真实滑动，避免被识别成 tap
    for i in 1...steps {
        let t = Double(i) / Double(steps)
        let e = t < 0.25 ? t * 0.4 : 0.1 + (t - 0.25) * 1.2
        let p = pt(from.x + (to.x - from.x) * min(e, 1), from.y + (to.y - from.y) * min(e, 1))
        post(.leftMouseDragged, p)
    }
    usleep(70_000)
    post(.leftMouseUp, to)
    print("drag (\(Int(x1)), \(Int(y1))) → (\(Int(x2)), \(Int(y2)))")

case "longpress":
    guard let x = Double(a[2]), let y = Double(a[3]) else { exit(2) }
    let hold = a.count > 4 ? (Double(a[4]) ?? 1.1) : 1.1
    let p = pt(x, y)
    move(p)
    usleep(120_000)
    post(.leftMouseDown, p)
    // 按住期间轻微抖动，让系统识别成长按而不是拖拽
    let end = Date().addingTimeInterval(hold)
    var i = 0
    while Date() < end {
        let jitter = Double(i % 2 == 0 ? 1 : -1) * 0.6
        post(.leftMouseDragged, pt(x + jitter, y + jitter))
        i += 1
    }
    post(.leftMouseUp, p)
    print("longpress (\(Int(x)), \(Int(y)))")

default:
    FileHandle.standardError.write("未知命令 \(a[1])\n".data(using: .utf8)!)
    exit(2)
}
