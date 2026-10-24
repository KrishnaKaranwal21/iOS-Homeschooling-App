import SwiftUI

enum LaunchStage { case onboarding, login, setup, main }

@Observable
final class AppState {
    var stage: LaunchStage = .onboarding
    var child: Child = Child.empty
    var tasks: [TaskItem] = MockData.tasks
    var events: [Event] = MockData.events

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

    func resetOnboarding() {
        UserDefaults.standard.removeObject(forKey: stageKey)
        child = Child.empty
        stage = .onboarding
    }
}
