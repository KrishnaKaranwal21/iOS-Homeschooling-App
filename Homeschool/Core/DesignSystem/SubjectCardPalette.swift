import SwiftUI

/// Home tasks and Progress subject cards share the same paper colours and subject symbols.
struct SubjectCardPalette {
    let paper: Color
    let ink: Color

    static let all = [
        SubjectCardPalette(paper: Color(hex: 0xEEE7FF), ink: Color(hex: 0x5940A5)),
        SubjectCardPalette(paper: Color(hex: 0xFFE7DD), ink: Color(hex: 0x9B4D3B)),
        SubjectCardPalette(paper: Color(hex: 0xE2F0E7), ink: Color(hex: 0x386553)),
        SubjectCardPalette(paper: Color(hex: 0xFFF1CE), ink: Color(hex: 0x88621E))
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
