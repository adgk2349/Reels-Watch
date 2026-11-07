import Foundation

enum ReelsError: Error, Equatable {
    case notFound
    case emptyRecipients
}

/// 앱이 필요로 하는 데이터 접근을 전부 추상화한 계층.
///
/// UI는 이 프로토콜만 알고, 실제 데이터 출처(목업, 자체 서버, 웹 세션 등)는
/// 구현체에서 갈아끼운다.
protocol ReelsProvider: Sendable {
    /// 릴스 피드. `cursor`가 nil이면 첫 페이지.
    func fetchReels(after cursor: String?) async throws -> Page<Reel>

    /// 특정 릴스의 댓글. `cursor`가 nil이면 첫 페이지.
    func fetchComments(reelID: Reel.ID, after cursor: String?) async throws -> Page<ReelComment>

    /// 릴스 좋아요 설정. 갱신된 릴스를 돌려준다.
    func setReelLiked(reelID: Reel.ID, liked: Bool) async throws -> Reel

    /// 댓글 하트 설정. 갱신된 댓글을 돌려준다.
    func setCommentLiked(reelID: Reel.ID, commentID: ReelComment.ID, liked: Bool) async throws -> ReelComment

    /// 공유 대상 DM방 목록 (최근 대화 순).
    func fetchDMThreads() async throws -> [DMThread]

    /// 릴스를 선택한 DM방들에 보낸다. 대상이 비어 있으면 `ReelsError.emptyRecipients`.
    func share(reelID: Reel.ID, to threadIDs: [DMThread.ID]) async throws
}
