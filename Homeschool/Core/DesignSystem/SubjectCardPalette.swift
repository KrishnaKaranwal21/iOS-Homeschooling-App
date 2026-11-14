import SwiftUI

/// Home tasks and Progress subject cards share the same paper colours and subject symbols.
struct SubjectCardPalette {
    let paper: Color
    let ink: Color

    static let all = [
        SubjectCardPalette(paper: Color.adaptive(0xEEE7FF, 0x2F263F), ink: Color.adaptive(0x5940A5, 0xD2BCFF)),
        SubjectCardPalette(paper: Color.adaptive(0xFFE7DD, 0x3D2A29), ink: Color.adaptive(0x9B4D3B, 0xF4B8A7)),
        SubjectCardPalette(paper: Color.adaptive(0xE2F0E7, 0x22352D), ink: Color.adaptive(0x386553, 0xA8DAC0)),
        SubjectCardPalette(paper: Color.adaptive(0xFFF1CE, 0x393122), ink: Color.adaptive(0x88621E, 0xE8CC8C))
    ]

    static func symbol(for subject: String) -> String {
        let key = LearningProgress.subjectKey(subject)
        switch key {
        case "mathematics": return "function"
        case "science": return "flask"
        case "computer skills": return "chevron.left.forwardslash.chevron.right"
        case "art & craft": return "paintpalette"
        case "english", "hindi": return "text.book.closed"
        default:
            if key.contains("plumbing") { return "wrench.and.screwdriver" }
            if key.contains("tailor") { return "scissors" }
            return "book.closed"
        }
    }
}
