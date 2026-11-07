import SwiftUI

/// 영상 화면. 제스처 스펙은 docs/GESTURES.md 참고.
struct ReelScreen: View {
    let model: ReelsViewModel

    @State private var crown: Double = 0
    @State private var showShare = false
    @State private var showHeartBurst = false

    var body: some View {
        ZStack {
            if let reel = model.currentReel {
                playerLayer(reel)
                    .allowsHitTesting(!model.isCommentsOpen)
            }
            if model.isCommentsOpen {
                CommentsOverlay(model: model)
                    .transition(.asymmetric(insertion: .move(edge: .trailing),
                                            removal: .move(edge: .leading)))
            }
        }
        .animation(.easeInOut(duration: 0.25), value: model.isCommentsOpen)
        .sheet(isPresented: $showShare) { ShareSheet(model: model) }
        .task(id: model.index) { await model.loadMoreReelsIfNeeded() }
    }

    // MARK: Player layer

    private func playerLayer(_ reel: Reel) -> some View {
        ZStack {
            ReelPosterView(reel: reel)
            bottomBar(reel)
            if showHeartBurst {
                Image(systemName: "heart.fill")
                    .font(.system(size: 54))
                    .foregroundStyle(.red)
                    .shadow(radius: 6)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .id(reel.id)
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 20).onEnded { value in
                if let swipe = SwipeIntent.classify(value.translation) {
                    model.handle(swipe)
                }
            }
        )
        .onTapGesture(count: 2) { toggleLike(reel) }
        // 용두: 댓글창이 닫혀 있을 때만 영상 이동. 열려 있으면 포커스를 놓아서
        // 댓글 ScrollView가 용두를 받게 한다.
        .focusable(!model.isCommentsOpen)
        .digitalCrownRotation(
            $crown,
            from: 0,
            through: Double(max(model.reels.count - 1, 0)),
            by: 1,
            sensitivity: .medium,
            isContinuous: false,
            isHapticFeedbackEnabled: true
        )
        .onChange(of: crown) { _, newValue in
            model.setIndex(Int(newValue.rounded()))
        }
        .onChange(of: model.index) { _, newIndex in
            if Int(crown.rounded()) != newIndex { crown = Double(newIndex) }
        }
    }

    private func bottomBar(_ reel: Reel) -> some View {
        VStack {
            Spacer()
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("@\(reel.authorHandle)")
                        .font(.caption.bold())
                    Text(reel.caption)
                        .font(.caption2)
                        .lineLimit(2)
                    Label(Formatting.count(reel.likeCount),
                          systemImage: reel.isLiked ? "heart.fill" : "heart")
                        .font(.caption2)
                        .foregroundStyle(reel.isLiked ? Color.red : Color.white.opacity(0.7))
                }
                Spacer(minLength: 4)
                Button {
                    showShare = true
                } label: {
                    Image(systemName: "paperplane")
                        .font(.body)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 10)
            .padding(.bottom, 4)
            .padding(.top, 24)
            .background(
                LinearGradient(colors: [.clear, .black.opacity(0.6)],
                               startPoint: .top, endPoint: .bottom)
            )
        }
    }

    // MARK: Actions

    private func toggleLike(_ reel: Reel) {
        let liked = !reel.isLiked
        Haptics.like()
        if liked { burstHeart() }
        Task { await model.setCurrentReelLiked(liked) }
    }

    private func burstHeart() {
        withAnimation(.spring(duration: 0.3)) { showHeartBurst = true }
        Task {
            try? await Task.sleep(for: .milliseconds(700))
            withAnimation(.easeOut(duration: 0.2)) { showHeartBurst = false }
        }
    }
}
