import SwiftUI

/// 댓글창. 읽기 전용이며 하트만 누를 수 있다.
/// 열려 있는 동안 용두와 위/아래 스와이프는 이 목록만 움직인다.
struct CommentsOverlay: View {
    let model: ReelsViewModel

    private var swipe: some Gesture {
        DragGesture(minimumDistance: 20).onEnded { value in
            if let intent = SwipeIntent.classify(value.translation) {
                model.handle(intent)
            }
        }
    }

    var body: some View {
        ZStack(alignment: .trailing) {
            // 패널 밖(영상이 비쳐 보이는 영역)을 탭하거나 스와이프해도 닫힌다.
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture { model.closeComments() }
                .gesture(swipe)

            panel
        }
    }

    private var panel: some View {
        VStack(alignment: .leading, spacing: 6) {
            header
            Divider()
            list
        }
        .padding(.horizontal, 10)
        .padding(.top, 6)
        .background {
            ZStack {
                Color.black.opacity(0.45)
                Rectangle().fill(.ultraThinMaterial)
            }
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
        .padding(.leading, 18)
        .ignoresSafeArea(edges: .bottom)
    }

    private var header: some View {
        VStack(spacing: 4) {
            Capsule()
                .fill(Color.secondary.opacity(0.6))
                .frame(width: 28, height: 3)
                .frame(maxWidth: .infinity)
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("댓글").font(.headline)
                Text("\(Formatting.count(model.currentReel?.commentCount ?? 0))개")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { model.closeComments() }
    }

    private var list: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 12) {
                ForEach(model.comments) { comment in
                    CommentRow(comment: comment) {
                        Haptics.like()
                        Task { await model.setCommentLiked(id: comment.id, liked: !comment.isLiked) }
                    }
                    .onAppear { Task { await model.loadMoreComments(after: comment) } }
                }
                if model.isLoadingComments {
                    ProgressView().frame(maxWidth: .infinity)
                } else if model.commentsFailed {
                    Text("댓글을 불러오지 못했어요")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                } else if model.comments.isEmpty {
                    Text("댓글이 없어요")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.bottom, 12)
        }
        // 가로로 우세한 드래그만 의미가 있으므로 세로 스크롤과 충돌하지 않는다.
        .simultaneousGesture(swipe)
        .task { await model.loadCommentsIfNeeded() }
    }
}

private struct CommentRow: View {
    let comment: ReelComment
    let onDoubleTap: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 6) {
            Circle()
                .fill(Color.gray.opacity(0.5))
                .frame(width: 26, height: 26)
                .overlay(Text(String(comment.authorHandle.prefix(1)).uppercased())
                    .font(.caption2.bold()))
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(comment.authorHandle)
                        .font(.caption2.bold())
                        .lineLimit(1)
                    Text(Formatting.relative(from: comment.createdAt))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Text(comment.text).font(.caption)
                Label(Formatting.count(comment.likeCount),
                      systemImage: comment.isLiked ? "heart.fill" : "heart")
                    .font(.caption2)
                    .foregroundStyle(comment.isLiked ? Color.red : Color.secondary)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture(count: 2, perform: onDoubleTap)
    }
}
