import Foundation

/// UI 개발과 테스트용 메모리 기반 구현체.
actor MockReelsProvider: ReelsProvider {
    private var reels: [Reel]
    private var commentsByReel: [Reel.ID: [ReelComment]]
    private let threads: [DMThread]
    private let pageSize: Int
    private let latency: Duration

    /// 공유가 실행된 기록. 테스트에서 확인용.
    private(set) var sharedLog: [(reelID: Reel.ID, threadIDs: [DMThread.ID])] = []

    init(pageSize: Int = 2, latency: Duration = .zero, now: Date = Date()) {
        self.pageSize = pageSize
        self.latency = latency
        self.reels = Self.makeReels()
        self.commentsByReel = Self.makeComments(now: now)
        self.threads = Self.makeThreads()
    }

    // MARK: - ReelsProvider

    func fetchReels(after cursor: String?) async throws -> Page<Reel> {
        try await simulateLatency()
        return paginate(reels, after: cursor)
    }

    func fetchComments(reelID: Reel.ID, after cursor: String?) async throws -> Page<ReelComment> {
        try await simulateLatency()
        guard reels.contains(where: { $0.id == reelID }) else { throw ReelsError.notFound }
        return paginate(commentsByReel[reelID] ?? [], after: cursor)
    }

    func setReelLiked(reelID: Reel.ID, liked: Bool) async throws -> Reel {
        try await simulateLatency()
        guard let index = reels.firstIndex(where: { $0.id == reelID }) else { throw ReelsError.notFound }
        if reels[index].isLiked != liked {
            reels[index].isLiked = liked
            reels[index].likeCount += liked ? 1 : -1
        }
        return reels[index]
    }

    func setCommentLiked(reelID: Reel.ID, commentID: ReelComment.ID, liked: Bool) async throws -> ReelComment {
        try await simulateLatency()
        guard var comments = commentsByReel[reelID],
              let index = comments.firstIndex(where: { $0.id == commentID })
        else { throw ReelsError.notFound }
        if comments[index].isLiked != liked {
            comments[index].isLiked = liked
            comments[index].likeCount += liked ? 1 : -1
            commentsByReel[reelID] = comments
        }
        return comments[index]
    }

    func fetchDMThreads() async throws -> [DMThread] {
        try await simulateLatency()
        return threads
    }

    func share(reelID: Reel.ID, to threadIDs: [DMThread.ID]) async throws {
        try await simulateLatency()
        guard reels.contains(where: { $0.id == reelID }) else { throw ReelsError.notFound }
        guard !threadIDs.isEmpty else { throw ReelsError.emptyRecipients }
        let known = Set(threads.map(\.id))
        guard threadIDs.allSatisfy(known.contains) else { throw ReelsError.notFound }
        sharedLog.append((reelID, threadIDs))
    }

    // MARK: - Helpers

    private func simulateLatency() async throws {
        if latency > .zero { try await Task.sleep(for: latency) }
    }

    /// 커서는 단순히 "다음 시작 인덱스"의 문자열.
    private func paginate<T: Sendable>(_ all: [T], after cursor: String?) -> Page<T> {
        let start = cursor.flatMap(Int.init) ?? 0
        guard start < all.count else { return Page(items: [], nextCursor: nil) }
        let end = min(start + pageSize, all.count)
        return Page(items: Array(all[start..<end]), nextCursor: end < all.count ? String(end) : nil)
    }

    // MARK: - Sample data

    private static func makeReels() -> [Reel] {
        [
            Reel(id: "reel-1", authorHandle: "mina.daily", caption: "오늘의 무드 ☁️",
                 mediaURL: nil, likeCount: 12_804, commentCount: 5, isLiked: false),
            Reel(id: "reel-2", authorHandle: "seoul.cafe", caption: "성수 신상 카페",
                 mediaURL: nil, likeCount: 3_290, commentCount: 0, isLiked: false),
            Reel(id: "reel-3", authorHandle: "hana_trip", caption: "제주 3박 4일 브이로그",
                 mediaURL: nil, likeCount: 8_117, commentCount: 1, isLiked: true),
        ]
    }

    private static func makeComments(now: Date) -> [Reel.ID: [ReelComment]] {
        func ago(_ hours: Double) -> Date { now.addingTimeInterval(-hours * 3600) }
        return [
            "reel-1": [
                ReelComment(id: "c1", authorHandle: "junho_97", avatarURL: nil,
                            text: "너무 예쁘다...♡", createdAt: ago(3), likeCount: 3_214, isLiked: false),
                ReelComment(id: "c2", authorHandle: "seul.bi", avatarURL: nil,
                            text: "이 메이크업 정보 좀 ㅠㅠ", createdAt: ago(2), likeCount: 482, isLiked: false),
                ReelComment(id: "c3", authorHandle: "minseo.k", avatarURL: nil,
                            text: "진짜 분위기 미쳤다", createdAt: ago(2), likeCount: 779, isLiked: false),
                ReelComment(id: "c4", authorHandle: "doyun_", avatarURL: nil,
                            text: "조명 어디 거예요?", createdAt: ago(1), likeCount: 56, isLiked: false),
                ReelComment(id: "c5", authorHandle: "yuri.lee", avatarURL: nil,
                            text: "저장해갑니다", createdAt: ago(0.5), likeCount: 12, isLiked: false),
            ],
            "reel-2": [],
            "reel-3": [
                ReelComment(id: "c6", authorHandle: "traveler_k", avatarURL: nil,
                            text: "숙소 어디예요?", createdAt: ago(5), likeCount: 8, isLiked: false),
            ],
        ]
    }

    private static func makeThreads() -> [DMThread] {
        [
            DMThread(id: "t1", title: "민서", avatarURL: nil, isGroup: false),
            DMThread(id: "t2", title: "대학 동기방", avatarURL: nil, isGroup: true),
            DMThread(id: "t3", title: "준호", avatarURL: nil, isGroup: false),
            DMThread(id: "t4", title: "가족", avatarURL: nil, isGroup: true),
            DMThread(id: "t5", title: "슬비", avatarURL: nil, isGroup: false),
            DMThread(id: "t6", title: "회사 사람들", avatarURL: nil, isGroup: true),
        ]
    }
}
