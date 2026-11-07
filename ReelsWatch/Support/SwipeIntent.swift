import CoreGraphics

/// 드래그 이동량을 네 방향 스와이프로 분류한다. 손가락이 움직인 방향 기준.
enum SwipeIntent: Equatable {
    case up, down, left, right

    /// - Parameters:
    ///   - translation: 드래그 종료 시점의 이동량.
    ///   - minDistance: 이보다 짧게 움직이면 스와이프로 보지 않는다.
    ///   - dominance: 주축이 반대축보다 이 배수 이상 커야 한다 (대각선 오작동 방지).
    static func classify(_ translation: CGSize,
                         minDistance: CGFloat = 30,
                         dominance: CGFloat = 1.5) -> SwipeIntent? {
        let dx = translation.width
        let dy = translation.height
        if abs(dx) >= minDistance, abs(dx) >= abs(dy) * dominance {
            return dx < 0 ? .left : .right
        }
        if abs(dy) >= minDistance, abs(dy) >= abs(dx) * dominance {
            return dy < 0 ? .up : .down
        }
        return nil
    }
}
