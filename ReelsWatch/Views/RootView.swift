import SwiftUI

@MainActor
struct RootView: View {
    @State private var model: ReelsViewModel

    init(provider: any ReelsProvider) {
        _model = State(initialValue: ReelsViewModel(provider: provider))
    }

    var body: some View {
        Group {
            switch model.loadState {
            case .idle, .loading:
                ProgressView()
            case .failed:
                VStack(spacing: 8) {
                    Text("불러오지 못했어요")
                    Button("다시 시도") { Task { await model.loadInitial() } }
                }
            case .loaded:
                if model.reels.isEmpty {
                    Text("영상이 없어요")
                } else {
                    ReelScreen(model: model)
                }
            }
        }
        .task { await model.loadInitial() }
    }
}
