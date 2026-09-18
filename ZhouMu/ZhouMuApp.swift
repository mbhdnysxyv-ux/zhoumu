import SwiftUI

@main
struct ZhouMuApp: App {
    @StateObject private var settings = AppSettings()

    init() {
        // 必须在启动完成前注册后台任务，否则 submit 会失败。
        BackgroundRefresh.register()
    }

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(settings)
                // 外观由设置里的三态开关决定；`.system` 时交回系统。
                .preferredColorScheme(settings.themeMode.colorScheme)
        }
    }
}
