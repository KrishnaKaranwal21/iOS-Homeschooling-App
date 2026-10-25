import Foundation

struct Parent: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let role: String
    let tags: String
    let distanceKm: Double
    let about: String
}

struct RoadmapStep: Identifiable {
    let id: Int
    let title: String
    let detail: String
    let symbol: String
}
