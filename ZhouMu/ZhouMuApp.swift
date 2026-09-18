import SwiftUI

@main
struct ZhouMuApp: App {
    @StateObject private var settings = AppSettings()

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(settings)
                // 外观由设置里的三态开关决定；`.system` 时交回系统。
                .preferredColorScheme(settings.themeMode.colorScheme)
        }
    }
}
