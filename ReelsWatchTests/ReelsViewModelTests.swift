import XCTest
@testable import ReelsWatch

@MainActor
final class ReelsViewModelTests: XCTestCase {
    private func makeLoadedModel(pageSize: Int = 2) async -> ReelsViewModel {
        let model = ReelsViewModel(provider: MockReelsProvider(pageSize: pageSize))
        await model.loadInitial()
        return model
    }

    // MARK: Feed / navigation

    func testLoadInitialPopulatesFirstPage() async {
        let model = await makeLoadedModel()
        XCTAssertEqual(model.loadState, .loaded)
        XCTAssertEqual(model.reels.count, 2)
        XCTAssertEqual(model.index, 0)
    }

    func testSetIndexClampsToBounds() async {
        let model = await makeLoadedModel()
        model.setIndex(99)
        XCTAssertEqual(model.index, 1)
        model.setIndex(-5)
        XCTAssertEqual(model.index, 0)
    }

    func testPrefetchLoadsNextPageNearEnd() async {
        let model = await makeLoadedModel(pageSize: 2)   // 총 3개 중 2개 로드됨
        XCTAssertEqual(model.reels.count, 2)
        await model.loadMoreReelsIfNeeded()
        XCTAssertEqual(model.reels.count, 3)
    }

    // MARK: Swipe routing

    func testSwipesMoveBetweenReelsWhenCommentsClosed() async {
        let model = await makeLoadedModel()
        model.handle(.up)
        XCTAssertEqual(model.index, 1)
        model.handle(.down)
        XCTAssertEqual(model.index, 0)
    }

    func testLeftSwipeTogglesCommentsAndRightSwipeAlsoCloses() async {
        let model = await makeLoadedModel()
        model.handle(.left)
        XCTAssertTrue(model.isCommentsOpen)
        model.handle(.left)
        XCTAssertFalse(model.isCommentsOpen)

        model.handle(.left)
        model.handle(.right)
        XCTAssertFalse(model.isCommentsOpen)
    }

    func testRightSwipeDoesNothingWhenCommentsClosed() async {
        let model = await makeLoadedModel()
        model.handle(.right)
        XCTAssertFalse(model.isCommentsOpen)
        XCTAssertEqual(model.index, 0)
    }

    func testReelDoesNotChangeWhileCommentsOpen() async {
        let model = await makeLoadedModel()
        model.handle(.left)
        model.handle(.up)
        model.handle(.down)
        model.setIndex(1)   // 용두
        XCTAssertEqual(model.index, 0)
    }

    // MARK: Comments

    func testOpeningCommentsLoadsCommentsForCurrentReel() async {
        let model = await makeLoadedModel()
        model.openComments()
        await model.loadCommentsIfNeeded()
        XCTAssertEqual(model.comments.first?.authorHandle, "junho_97")
    }

    func testCommentsPaginateOnLastRowAppearing() async {
        let model = await makeLoadedModel(pageSize: 2)
        model.openComments()
        await model.loadCommentsIfNeeded()
        XCTAssertEqual(model.comments.count, 2)

        await model.loadMoreComments(after: model.comments[0])   // 마지막 행이 아니면 무시
        XCTAssertEqual(model.comments.count, 2)

        await model.loadMoreComments(after: model.comments[1])
        XCTAssertEqual(model.comments.count, 4)
    }

    func testCommentsReloadForDifferentReel() async {
        let model = await makeLoadedModel()
        await model.loadMoreReelsIfNeeded()
        model.openComments()
        await model.loadCommentsIfNeeded()
        let first = model.comments.map(\.id)

        model.closeComments()
        model.setIndex(1)   // reel-2: 댓글 없음
        model.openComments()
        await model.loadCommentsIfNeeded()
        XCTAssertNotEqual(model.comments.map(\.id), first)
        XCTAssertTrue(model.comments.isEmpty)
    }

    // MARK: Likes

    func testReelLikeUpdatesState() async {
        let model = await makeLoadedModel()
        let before = model.currentReel!
        await model.setCurrentReelLiked(true)
        XCTAssertTrue(model.currentReel!.isLiked)
        XCTAssertEqual(model.currentReel!.likeCount, before.likeCount + 1)
        await model.setCurrentReelLiked(false)
        XCTAssertEqual(model.currentReel!.likeCount, before.likeCount)
    }

    func testCommentHeartUpdatesState() async {
        let model = await makeLoadedModel()
        model.openComments()
        await model.loadCommentsIfNeeded()
        let target = model.comments[0]
        await model.setCommentLiked(id: target.id, liked: true)
        XCTAssertTrue(model.comments[0].isLiked)
        XCTAssertEqual(model.comments[0].likeCount, target.likeCount + 1)
    }

    // MARK: Share

    func testShareRequiresSelectionAndSucceedsWithThreads() async {
        let model = await makeLoadedModel()
        await model.loadThreadsIfNeeded()
        XCTAssertTrue(model.threadsLoaded)

        let none = await model.shareCurrentReel(to: [])
        XCTAssertFalse(none)

        let ok = await model.shareCurrentReel(to: ["t1", "t3"])
        XCTAssertTrue(ok)
    }
}
