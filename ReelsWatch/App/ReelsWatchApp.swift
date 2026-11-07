import SwiftUI

@main
struct ReelsWatchApp: App {
    /// 데이터 소스는 여기서만 정한다. 지금은 목업.
    private let provider: any ReelsProvider = MockReelsProvider(latency: .milliseconds(200))

    var body: some Scene {
        WindowGroup {
            RootView(provider: provider)
        }
    }
}
