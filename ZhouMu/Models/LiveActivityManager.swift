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
    func sync(settings: AppSettings, now: Date = Date()) async {
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

        await updateActivity(settings: settings, classes: classes, now: now)
        scheduleNotifications(classes: classes, now: now)
    }

    // MARK: - 实时活动

    private func updateActivity(settings: AppSettings,
                                classes: [ScheduledClass],
                                now: Date) async {
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

        // 已经有一个就更新，没有就新建
        if let existing = Activity<ClassActivityAttributes>.activities.first {
            await existing.update(ActivityContent(state: state, staleDate: nil))
        } else {
            _ = try? Activity.request(attributes: attributes,
                                      content: ActivityContent(state: state, staleDate: nil),
                                      pushType: nil)
        }
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
