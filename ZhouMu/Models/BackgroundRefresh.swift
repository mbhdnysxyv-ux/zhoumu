import Foundation

#if os(iOS)
import BackgroundTasks
import os

/// 用系统的后台刷新，在课程边界之后找机会醒一次，把实时活动清理掉。
///
/// ## 为什么需要它
/// 苹果要求实时活动保持 `active` 才能留在灵动岛，而 `end()` 会让它**立刻**
/// 从灵动岛消失（只有锁屏保留到 dismissal 时间）。所以没法"安排到点消失"，
/// App 不运行时活动就会停在下课时间不动。
///
/// 精确到秒的做法是 APNs 的 push-to-end，但那个需要付费开发者账号。
/// 免费的折中就是这里：给系统排一个后台刷新任务，让它**在课后找机会**唤醒 App
/// 去把活动更新或结束掉。
///
/// ## 局限（写清楚，免得以为是 bug）
/// `earliestBeginDate` 是"最早可以开始"，**不是定时器**。iOS 会按自己的电量、
/// 网络、使用习惯来排期，可能课后几分钟就跑，也可能拖很久甚至不跑。
/// 所以它是"尽力而为"，不是"精确到点"。
enum BackgroundRefresh {

    private static let log = Logger(subsystem: "com.zhoumu.weekdisplay", category: "background")

    /// 任务标识符。必须和 Info.plist 里 `BGTaskSchedulerPermittedIdentifiers`
    /// 的那一项完全一致（plist 里写的是 `$(APP_BUNDLE_ID).refresh`）。
    static var identifier: String {
        (Bundle.main.bundleIdentifier ?? "com.zhoumu.weekdisplay") + ".refresh"
    }

    // MARK: - 注册

    /// 必须在 App 启动完成前调用，否则提交任务会失败。
    static func register() {
        let ok = BGTaskScheduler.shared.register(forTaskWithIdentifier: identifier, using: nil) { task in
            guard let refresh = task as? BGAppRefreshTask else {
                task.setTaskCompleted(success: false)
                return
            }
            handle(refresh)
        }
        log.info("register(\(identifier, privacy: .public)) -> \(ok, privacy: .public)")
    }

    // MARK: - 排期

    /// 安排下一次唤醒：时间点取"下一个需要更新实时活动的边界"。
    static func schedule(settings: AppSettings, now: Date = Date()) {
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: identifier)

        guard settings.liveActivityEnabled else { return }
        let classes = settings.classes(for: now)
        guard let boundary = nextBoundary(classes: classes, now: now) else {
            log.info("no boundary today, skip")
            return
        }

        let request = BGAppRefreshTaskRequest(identifier: identifier)
        request.earliestBeginDate = boundary
        do {
            try BGTaskScheduler.shared.submit(request)
            log.info("submit ok, earliest = \(boundary, privacy: .public)")
        } catch {
            // 排不上就算了：这本来就是个尽力而为的优化，失败不影响主功能。
            // 但要把原因记下来，否则出问题没法查。
            log.error("submit failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    /// 下一个边界：正在上的 → 本节下课；还没上 → 下节上课；都没有 → nil。
    private static func nextBoundary(classes: [ScheduledClass], now: Date) -> Date? {
        if let current = classes.first(where: { $0.start <= now && now < $0.end }) {
            return current.end.addingTimeInterval(5)
        }
        if let next = classes.first(where: { now < $0.start }) {
            return next.start.addingTimeInterval(5)
        }
        return nil
    }

    // MARK: - 执行

    private static func handle(_ task: BGAppRefreshTask) {
        // 先把下一次排上，否则这个任务只会跑一次。
        let settings = AppSettings()
        schedule(settings: settings)

        task.expirationHandler = {
            task.setTaskCompleted(success: false)
        }

        Task { @MainActor in
            // sync 内部会判断：课上完了就结束活动，还没上完就更新成当前状态。
            await LiveActivityManager.shared.sync(settings: settings)
            task.setTaskCompleted(success: true)
        }
    }
}
#endif
