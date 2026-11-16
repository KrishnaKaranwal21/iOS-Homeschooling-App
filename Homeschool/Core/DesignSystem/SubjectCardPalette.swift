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

    /// One symbol per subject, so a card or pill is recognisable before its name is read.
    static func symbol(for subject: String) -> String {
        let key = LearningProgress.subjectKey(subject)
        if let symbol = exactSymbols[key] { return symbol }
        for (needle, symbol) in partialSymbols where key.contains(needle) { return symbol }
        return "book.closed"
    }

    private static let exactSymbols: [String: String] = [
        // Maths and sciences
        "mathematics": "function",
        "science": "flask",
        "science & technology": "atom",
        "physics": "atom",
        "chemistry": "flask",
        "biology": "microbe",
        "environmental studies (evs)": "tree",
        "environmental science": "leaf.arrow.circlepath",
        // Computing
        "computer skills": "chevron.left.forwardslash.chevron.right",
        "computer science": "chevron.left.forwardslash.chevron.right",
        "basic computing": "desktopcomputer",
        "data entry operations": "keyboard",
        "certificate in desktop publishing": "doc.richtext",
        // Humanities and commerce
        "social science": "person.3",
        "history": "hourglass",
        "geography": "map",
        "political science": "building.columns",
        "sociology": "person.2",
        "psychology": "brain.head.profile",
        "economics": "chart.line.uptrend.xyaxis",
        "business studies": "briefcase",
        "accountancy": "indianrupeesign.circle",
        "indian culture & heritage": "theatermasks",
        "introduction to law": "doc.text.magnifyingglass",
        "mass communication": "megaphone",
        "tourism": "airplane",
        "library & information science": "books.vertical",
        "military studies": "shield",
        "military history": "flag",
        // Languages
        "english": "textformat.abc",
        "regional language": "character.bubble",
        // Arts, health and skills
        "art & craft": "paintpalette",
        "painting": "paintpalette",
        "creative crafts": "paintbrush.pointed",
        "home science": "house",
        "physical education": "figure.run",
        "yoga": "figure.mind.and.body",
        "yoga & health": "figure.mind.and.body",
        "cutting & tailoring": "scissors",
        "basic agriculture": "leaf",
        "vermicomposting": "ant",
        "basic plumbing & electrical wiring": "wrench.and.screwdriver",
        "bakery & confectionery": "birthday.cake",
        "carpentry": "hammer",
        "solar energy technician": "sun.max"
    ]

    /// Every other language shares the language-book symbol; these also catch older or renamed subjects.
    private static let partialSymbols: [(String, String)] = [
        ("plumbing", "wrench.and.screwdriver"),
        ("tailor", "scissors"),
        ("hindi", "character.book.closed"), ("urdu", "character.book.closed"),
        ("sanskrit", "character.book.closed"), ("arabic", "character.book.closed"),
        ("persian", "character.book.closed"), ("bengali", "character.book.closed"),
        ("marathi", "character.book.closed"), ("telugu", "character.book.closed"),
        ("gujarati", "character.book.closed"), ("punjabi", "character.book.closed"),
        ("assamese", "character.book.closed"), ("nepali", "character.book.closed"),
        ("odia", "character.book.closed"), ("malayalam", "character.book.closed"),
        ("kannada", "character.book.closed"), ("tamil", "character.book.closed")
    ]
}
