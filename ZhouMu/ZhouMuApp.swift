import SwiftUI

@main
struct ZhouMuApp: App {
    @StateObject private var settings = AppSettings()

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(settings)
                // 界面固定为「橙白」浅色，避免深色模式下配色翻转。
                .preferredColorScheme(.light)
        }
    }
}
