import Foundation

struct Event: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let day: Int
    let month: String
    let time: String
    let host: String
    let place: String
    let ages: String
    let symbol: String
    var isRegistered = false
}
