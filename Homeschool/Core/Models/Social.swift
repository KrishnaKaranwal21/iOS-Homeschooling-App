import Foundation

struct Parent: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let role: String
    let tags: String
    let distanceKm: Double
    let about: String
}

struct ChatThread: Identifiable {
    let id = UUID()
    let title: String
    let preview: String
    let time: String
    var unread = 0
    var isGroup = false
}

struct Message: Identifiable {
    let id = UUID()
    let text: String
    let time: String
    let isMine: Bool
}

struct RoadmapStep: Identifiable {
    let id: Int
    let title: String
    let detail: String
    let symbol: String
}
