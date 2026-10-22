import SwiftUI
import Combine

enum LaunchStage { case onboarding, setup, main }

final class AppState: ObservableObject {
    @Published var stage: LaunchStage = .onboarding
    @Published var child: Child = Child.sample
    @Published var tasks: [TaskItem] = MockData.tasks
    @Published var events: [Event] = MockData.events

    private let stageKey = "stage"

    init() {
        if UserDefaults.standard.string(forKey: stageKey) == "main" {
            stage = .main
        }
    }

    func advance(to newStage: LaunchStage) {
        stage = newStage
        if newStage == .main {
            UserDefaults.standard.set("main", forKey: stageKey)
        }
    }

    func toggle(_ task: TaskItem) {
        guard let i = tasks.firstIndex(of: task) else { return }
        tasks[i].isDone.toggle()
    }
}
