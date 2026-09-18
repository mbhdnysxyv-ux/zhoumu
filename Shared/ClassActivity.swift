import Foundation

#if canImport(ActivityKit) && os(iOS)
import ActivityKit

/// 灵动岛 / 锁屏实时活动的数据契约。
///
/// 关键设计：**倒计时和进度条交给 SwiftUI 自己走**。
/// 苹果不允许 App 在后台随意刷新实时活动，所以凡是「随时间变化」的东西
/// 都用 `Text(timerInterval:)` / `ProgressView(timerInterval:)` 交给系统渲染，
/// 不需要 App 参与。只有「现在是第几节、哪个科目」这种内容变更才需要 App 唤醒时更新。
struct ClassActivityAttributes: ActivityAttributes {

    /// 会随时间变化的部分——由 App 在唤醒时刷新。
    struct ContentState: Codable, Hashable {
        /// 小字：「周一」「课间」「当日晚课」。
        var caption: String
        /// 大字：当前或下一节的科目。
        var subject: String
        /// 状态：before / in / rest / done / none。
        var phase: String
        /// 本节范围（上课中才有），驱动「还剩」倒计时和进度条。
        var currentStart: Date?
        var currentEnd: Date?
        /// 下节开始时间，驱动「距上课」倒计时。
        var nextStart: Date?
        /// 是否排出了时间轴（没排出来时只能显示当日晚课）。
        var hasTimeline: Bool
    }

    /// 活动期间不变的部分：当天完整课表。
    var dayTitle: String
    var items: [Item]

    struct Item: Codable, Hashable, Identifiable {
        var id: String
        var subject: String
        var start: Date
        var end: Date
        var kindLabel: String
    }
}
#endif
