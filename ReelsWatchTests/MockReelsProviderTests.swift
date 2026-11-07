import XCTest
@testable import ReelsWatch

final class MockReelsProviderTests: XCTestCase {
    func testReelsArePaginatedUntilCursorIsNil() async throws {
        let provider = MockReelsProvider(pageSize: 2)

        let first = try await provider.fetchReels(after: nil)
        XCTAssertEqual(first.items.count, 2)
        XCTAssertNotNil(first.nextCursor)

        let second = try await provider.fetchReels(after: first.nextCursor)
        XCTAssertEqual(second.items.count, 1)
        XCTAssertNil(second.nextCursor)
    }

    func testReelLikeTogglesCountAndIsIdempotent() async throws {
        let provider = MockReelsProvider()
        let before = try await provider.fetchReels(after: nil).items[0]
        XCTAssertFalse(before.isLiked)

        let liked = try await provider.setReelLiked(reelID: before.id, liked: true)
        XCTAssertTrue(liked.isLiked)
        XCTAssertEqual(liked.likeCount, before.likeCount + 1)

        let again = try await provider.setReelLiked(reelID: before.id, liked: true)
        XCTAssertEqual(again.likeCount, liked.likeCount)

        let unliked = try await provider.setReelLiked(reelID: before.id, liked: false)
        XCTAssertEqual(unliked.likeCount, before.likeCount)
    }

    func testCommentsPaginateAndHeartPersists() async throws {
        let provider = MockReelsProvider(pageSize: 3)
        let page = try await provider.fetchComments(reelID: "reel-1", after: nil)
        XCTAssertEqual(page.items.count, 3)
        XCTAssertEqual(page.nextCursor, "3")

        let target = page.items[0]
        let hearted = try await provider.setCommentLiked(reelID: "reel-1", commentID: target.id, liked: true)
        XCTAssertTrue(hearted.isLiked)
        XCTAssertEqual(hearted.likeCount, target.likeCount + 1)

        let refetched = try await provider.fetchComments(reelID: "reel-1", after: nil)
        XCTAssertTrue(refetched.items[0].isLiked)
    }

    func testUnknownReelThrowsNotFound() async {
        let provider = MockReelsProvider()
        do {
            _ = try await provider.fetchComments(reelID: "nope", after: nil)
            XCTFail("expected notFound")
        } catch {
            XCTAssertEqual(error as? ReelsError, .notFound)
        }
    }

    func testShareValidatesRecipients() async throws {
        let provider = MockReelsProvider()

        do {
            try await provider.share(reelID: "reel-1", to: [])
            XCTFail("expected emptyRecipients")
        } catch {
            XCTAssertEqual(error as? ReelsError, .emptyRecipients)
        }

        do {
            try await provider.share(reelID: "reel-1", to: ["unknown"])
            XCTFail("expected notFound")
        } catch {
            XCTAssertEqual(error as? ReelsError, .notFound)
        }

        try await provider.share(reelID: "reel-1", to: ["t1", "t2"])
        let log = await provider.sharedLog
        XCTAssertEqual(log.count, 1)
        XCTAssertEqual(log[0].threadIDs, ["t1", "t2"])
    }
}
