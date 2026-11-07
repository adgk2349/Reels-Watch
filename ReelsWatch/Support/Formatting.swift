import Foundation

enum Formatting {
    /// 3214 -> "3,214"
    static func count(_ n: Int) -> String {
        var out = ""
        for (i, ch) in String(abs(n)).reversed().enumerated() {
            if i > 0, i % 3 == 0 { out.append(",") }
            out.append(ch)
        }
        return (n < 0 ? "-" : "") + String(out.reversed())
    }

    /// 짧은 상대 시간: 방금 / N분 / N시간 / N일
    static func relative(from date: Date, now: Date = Date()) -> String {
        let seconds = Int(now.timeIntervalSince(date))
        switch seconds {
        case ..<60: return "방금"
        case ..<3_600: return "\(seconds / 60)분"
        case ..<86_400: return "\(seconds / 3_600)시간"
        default: return "\(seconds / 86_400)일"
        }
    }
}
