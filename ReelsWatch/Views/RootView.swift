import SwiftUI

/// 배선 확인용 임시 화면. 다음 단계에서 영상 화면(제스처 포함)으로 교체한다.
struct RootView: View {
    let provider: any ReelsProvider

    @State private var reels: [Reel] = []
    @State private var errorMessage: String?

    var body: some View {
        Group {
            if let errorMessage {
                Text(errorMessage)
            } else if reels.isEmpty {
                ProgressView()
            } else {
                List(reels) { reel in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(reel.authorHandle).font(.headline)
                        Text(reel.caption).font(.caption)
                    }
                }
            }
        }
        .task {
            do {
                reels = try await provider.fetchReels(after: nil).items
            } catch {
                errorMessage = "불러오지 못했어요"
            }
        }
    }
}
