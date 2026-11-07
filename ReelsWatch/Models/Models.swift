import Foundation

/// 릴스 한 개.
struct Reel: Identifiable, Hashable, Sendable {
    let id: String
    let authorHandle: String
    let caption: String
    /// 재생 가능한 영상 주소. 목업에서는 nil일 수 있다.
    let mediaURL: URL?
    var likeCount: Int
    var commentCount: Int
    var isLiked: Bool
}

/// 릴스에 달린 댓글 (읽기 전용 + 하트만 가능).
struct ReelComment: Identifiable, Hashable, Sendable {
    let id: String
    let authorHandle: String
    let avatarURL: URL?
    let text: String
    let createdAt: Date
    var likeCount: Int
    var isLiked: Bool
}

/// 공유 대상 DM방. 대화 기능은 없고 "선택해서 보내기"에만 쓴다.
struct DMThread: Identifiable, Hashable, Sendable {
    let id: String
    let title: String
    let avatarURL: URL?
    let isGroup: Bool
}

/// 커서 기반 페이지 결과. `nextCursor == nil`이면 마지막 페이지.
struct Page<Element: Sendable>: Sendable {
    let items: [Element]
    let nextCursor: String?
}
