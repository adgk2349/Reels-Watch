import SwiftUI

/// 영상 대신 보여주는 자리표시 화면. 실제 재생은 데이터 소스 연동 단계에서 붙인다.
struct ReelPosterView: View {
    let reel: Reel

    private static let palettes: [[Color]] = [
        [Color(red: 0.36, green: 0.27, blue: 0.40), Color(red: 0.12, green: 0.09, blue: 0.16)],
        [Color(red: 0.20, green: 0.36, blue: 0.42), Color(red: 0.05, green: 0.12, blue: 0.16)],
        [Color(red: 0.45, green: 0.30, blue: 0.24), Color(red: 0.14, green: 0.08, blue: 0.07)],
    ]

    /// 앱을 다시 켜도 같은 릴스는 같은 색이 되도록 id 문자열로 결정한다.
    private var colors: [Color] {
        let seed = reel.id.unicodeScalars.reduce(0) { $0 &+ Int($1.value) }
        return Self.palettes[seed % Self.palettes.count]
    }

    var body: some View {
        ZStack {
            LinearGradient(colors: colors, startPoint: .top, endPoint: .bottom)
            Image(systemName: "play.fill")
                .font(.title)
                .foregroundStyle(.white.opacity(0.25))
        }
        .ignoresSafeArea()
    }
}
