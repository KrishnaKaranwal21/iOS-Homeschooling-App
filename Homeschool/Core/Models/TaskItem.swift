import Foundation

struct TaskItem: Identifiable, Equatable {
    let id = UUID()
    let subject: String
    let title: String
    var isDone = false
}
