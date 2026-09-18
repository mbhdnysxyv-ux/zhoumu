import Foundation
import UserNotifications

#if canImport(ActivityKit) && os(iOS)
import ActivityKit

/// 灵动岛 / 锁屏实时活动 + 上下课前 5 分钟的本地通知。
///
/// ## 为什么用本地通知而不是「更新实时活动」来提醒
/// 苹果不允许 App 在后台按自己的意愿刷新实时活动（除非有服务器推 APNs）。
/// 而本地通知是系统级定时任务，**App 关着也能准时响**，所以：
/// - **提醒**：交给本地通知，时间精确到秒；
/// - **倒计时 / 进度条**：交给实时活动里的 `Text(timerInterval:)`，
///   由系统渲染，同样不需要 App 参与；
/// - **课名切换**：需要 App 运行时才能更新（打开 App、切后台时各刷一次）。
@available(iOS 16.1, *)
@MainActor
final class LiveActivityManager {

    static let shared = LiveActivityManager()

    /// 每节课前后各提前多少秒提醒。
    static let leadTime: TimeInterval = 5 * 60

    private init() {}

    // MARK: - 同步

    /// 让实时活动与通知跟上当前设置。在 App 出现、切后台、课程边界时调用。
    ///
    /// - Parameter goingToBackground: 切后台时传 true（保留参数是为了让调用方语义清楚，
    ///   当前实现下前后台行为一致）。
    func sync(settings: AppSettings, now: Date = Date(), goingToBackground: Bool = false) async {
        guard settings.liveActivityEnabled else {
            await endActivity()
            cancelNotifications()
            return
        }

        let classes = settings.classes(for: now)
        guard !classes.isEmpty else {
            await endActivity()
            cancelNotifications()
            return
        }

        // 当天全上完了 → 直接移除活动，别让「完课」的卡片挂一整天。
        if case .finished = ClassSchedule.state(at: now, classes: classes) {
            await endActivity()
            cancelNotifications()
            return
        }

        await updateActivity(settings: settings, classes: classes, now: now,
                             scheduleDismissal: goingToBackground)
        scheduleNotifications(classes: classes, now: now)
    }

    // MARK: - 实时活动

    private func updateActivity(settings: AppSettings,
                                classes: [ScheduledClass],
                                now: Date,
                                scheduleDismissal: Bool) async {
        let content = ClassSchedule.ringContent(
            at: now,
            tables: [.regular: settings.regular, .evening: settings.evening],
            displayWeek: settings.displayWeek(referenceDate: now)
        )

        let state = ClassActivityAttributes.ContentState(
            caption: content.caption,
            subject: content.subject,
            phase: content.phase,
            currentStart: content.currentStart,
            currentEnd: content.currentEnd,
            nextStart: content.nextStart,
            hasTimeline: true
        )

        let items = classes.map {
            ClassActivityAttributes.Item(id: $0.id,
                                         subject: $0.subject,
                                         start: $0.start,
                                         end: $0.end,
                                         kindLabel: $0.kind.label)
        }
        let attributes = ClassActivityAttributes(dayTitle: now.zhoumu_shortText, items: items)

        // 内容过期的提示时间：本节下课那一刻。
        // 过了这个点系统会把活动标记成「过时」（变暗），是给用户的额外提示。
        let stale = classes.first { $0.start <= now && now < $0.end }?.end
            ?? classes.first { now < $0.start }?.end

        let activityContent = ActivityContent(state: state, staleDate: stale)

        guard let current = Activity<ClassActivityAttributes>.activities.first else {
            _ = try? Activity.request(attributes: attributes,
                                      content: activityContent, pushType: nil)
            return
        }

        // 注意：这里【不能】用 `end(…, dismissalPolicy: .after(下课时间))` 来安排自动消失。
        //
        // 实测（iPhone 17 Pro 模拟器 / iOS 26.5）：`end()` 会让活动
        // **立刻从灵动岛消失**，只有锁屏会把它保留到 dismissal 时间。
        // 结果是整节课灵动岛都空着——比"停在 0:00"还糟。
        //
        // 苹果的设计是：活动必须保持 active 才能留在灵动岛；
        // 想在精确时刻远程结束，唯一的官方途径是 APNs 的 push-to-end（需要服务器）。
        // 所以这里保持 active，靠 staleDate 让系统标记"内容已过时"，
        // 等 App 下次运行再把状态追平或结束。
        await current.update(activityContent)
    }

    /// 结束所有实时活动（关闭开关、今天没课时调用）。
    func endActivity() async {
        for activity in Activity<ClassActivityAttributes>.activities {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
    }

    // MARK: - 本地通知

    private func scheduleNotifications(classes: [ScheduledClass], now: Date) {
        let center = UNUserNotificationCenter.current()

        center.requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }

        // 先清掉今天之前排的，避免重复
        center.removeAllPendingNotificationRequests()

        for item in classes {
            let startLead = item.start.addingTimeInterval(-Self.leadTime)
            if startLead > now {
                add(center: center,
                    id: "start-\(item.id)",
                    at: startLead,
                    title: "\(item.subject) 快上课了",
                    body: "距离上课还有 5 分钟" + "（\(item.kind.label) 第 \(item.period) 节）")
            }

            let endLead = item.end.addingTimeInterval(-Self.leadTime)
            if endLead > now {
                add(center: center,
                    id: "end-\(item.id)",
                    at: endLead,
                    title: "\(item.subject) 快下课了",
                    body: "距离下课还有 5 分钟")
            }
        }
    }

    private func add(center: UNUserNotificationCenter,
                     id: String,
                     at date: Date,
                     title: String,
                     body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let comps = SemesterCalculator.calendar.dateComponents(
            [.year, .month, .day, .hour, .minute, .second], from: date
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
    }

    private func cancelNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}
#endif
