import Foundation
import Observation

/// 영상 화면 전체의 상태와 동작. 뷰는 이 객체만 바라본다.
@MainActor
@Observable
final class ReelsViewModel {
    enum LoadState: Equatable { case idle, loading, loaded, failed }

    // MARK: State

    private(set) var loadState: LoadState = .idle
    private(set) var reels: [Reel] = []
    private(set) var index = 0

    private(set) var isCommentsOpen = false
    private(set) var comments: [ReelComment] = []
    private(set) var isLoadingComments = false
    private(set) var commentsFailed = false

    private(set) var threads: [DMThread] = []
    private(set) var threadsLoaded = false

    var currentReel: Reel? { reels.indices.contains(index) ? reels[index] : nil }

    // MARK: Internals

    @ObservationIgnored private let provider: any ReelsProvider
    @ObservationIgnored private var nextReelCursor: String?
    @ObservationIgnored private var isLoadingMoreReels = false
    @ObservationIgnored private var commentsReelID: Reel.ID?
    @ObservationIgnored private var nextCommentCursor: String?
    @ObservationIgnored private var isLoadingMoreComments = false

    /// 끝에서 이 개수 이내로 다가가면 다음 페이지를 미리 불러온다.
    @ObservationIgnored private let prefetchDistance = 2

    init(provider: any ReelsProvider) {
        self.provider = provider
    }

    // MARK: Feed

    func loadInitial() async {
        guard loadState != .loading else { return }
        loadState = .loading
        do {
            let page = try await provider.fetchReels(after: nil)
            reels = page.items
            nextReelCursor = page.nextCursor
            index = 0
            loadState = .loaded
        } catch {
            loadState = .failed
        }
    }

    func loadMoreReelsIfNeeded() async {
        guard loadState == .loaded,
              let cursor = nextReelCursor,
              !isLoadingMoreReels,
              index >= reels.count - 1 - prefetchDistance
        else { return }
        isLoadingMoreReels = true
        defer { isLoadingMoreReels = false }
        if let page = try? await provider.fetchReels(after: cursor) {
            reels.append(contentsOf: page.items)
            nextReelCursor = page.nextCursor
        }
    }

    /// 댓글창이 열려 있는 동안에는 영상 이동을 막는다.
    func setIndex(_ newIndex: Int) {
        guard !isCommentsOpen, !reels.isEmpty else { return }
        let clamped = min(max(newIndex, 0), reels.count - 1)
        if clamped != index { index = clamped }
    }

    func move(by delta: Int) { setIndex(index + delta) }

    // MARK: Swipe routing

    /// 제스처 스펙(docs/GESTURES.md)의 스와이프 처리.
    func handle(_ swipe: SwipeIntent) {
        if isCommentsOpen {
            switch swipe {
            case .left, .right: closeComments()
            case .up, .down: break   // 댓글 목록 스크롤에 맡긴다
            }
        } else {
            switch swipe {
            case .up: move(by: 1)
            case .down: move(by: -1)
            case .left: openComments()
            case .right: break
            }
        }
    }

    // MARK: Comments

    func openComments() {
        guard currentReel != nil, !isCommentsOpen else { return }
        isCommentsOpen = true
    }

    func closeComments() { isCommentsOpen = false }

    func loadCommentsIfNeeded() async {
        guard let reel = currentReel, commentsReelID != reel.id else { return }
        commentsReelID = reel.id
        comments = []
        nextCommentCursor = nil
        commentsFailed = false
        isLoadingComments = true
        defer { isLoadingComments = false }
        do {
            let page = try await provider.fetchComments(reelID: reel.id, after: nil)
            guard commentsReelID == reel.id else { return }
            comments = page.items
            nextCommentCursor = page.nextCursor
        } catch {
            guard commentsReelID == reel.id else { return }
            commentsReelID = nil   // 다시 열면 재시도
            commentsFailed = true
        }
    }

    /// 마지막 댓글이 화면에 나타나면 다음 페이지를 불러온다.
    func loadMoreComments(after comment: ReelComment) async {
        guard comment.id == comments.last?.id,
              let reelID = commentsReelID,
              let cursor = nextCommentCursor,
              !isLoadingMoreComments
        else { return }
        isLoadingMoreComments = true
        defer { isLoadingMoreComments = false }
        if let page = try? await provider.fetchComments(reelID: reelID, after: cursor),
           commentsReelID == reelID {
            comments.append(contentsOf: page.items)
            nextCommentCursor = page.nextCursor
        }
    }

    // MARK: Likes (optimistic)

    func setCurrentReelLiked(_ liked: Bool) async {
        guard let original = currentReel, original.isLiked != liked else { return }
        var optimistic = original
        optimistic.isLiked = liked
        optimistic.likeCount += liked ? 1 : -1
        replaceReel(optimistic)
        do {
            replaceReel(try await provider.setReelLiked(reelID: original.id, liked: liked))
        } catch {
            replaceReel(original)
        }
    }

    func setCommentLiked(id commentID: ReelComment.ID, liked: Bool) async {
        guard let reelID = commentsReelID,
              let original = comments.first(where: { $0.id == commentID }),
              original.isLiked != liked
        else { return }
        var optimistic = original
        optimistic.isLiked = liked
        optimistic.likeCount += liked ? 1 : -1
        replaceComment(optimistic)
        do {
            replaceComment(try await provider.setCommentLiked(reelID: reelID, commentID: commentID, liked: liked))
        } catch {
            replaceComment(original)
        }
    }

    // MARK: Share

    func loadThreadsIfNeeded() async {
        guard !threadsLoaded else { return }
        if let loaded = try? await provider.fetchDMThreads() {
            threads = loaded
            threadsLoaded = true
        }
    }

    /// 현재 릴스를 선택한 방들에 보낸다. 방 순서는 목록 순서를 따른다.
    func shareCurrentReel(to selected: Set<DMThread.ID>) async -> Bool {
        guard let reel = currentReel, !selected.isEmpty else { return false }
        let ids = threads.map(\.id).filter(selected.contains)
        do {
            try await provider.share(reelID: reel.id, to: ids)
            return true
        } catch {
            return false
        }
    }

    // MARK: Helpers

    private func replaceReel(_ reel: Reel) {
        if let i = reels.firstIndex(where: { $0.id == reel.id }) { reels[i] = reel }
    }

    private func replaceComment(_ comment: ReelComment) {
        if let i = comments.firstIndex(where: { $0.id == comment.id }) { comments[i] = comment }
    }
}
