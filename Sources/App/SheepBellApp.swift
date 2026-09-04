// SheepBell v0.2
import SwiftUI

@main
struct SheepBellApp: App {
    @State private var store: HerdrStore

    init() {
        let store = HerdrStore()
        _store = State(initialValue: store)
        store.start()
        if CommandLine.arguments.contains("--sheepbell-test-notification") {
            Task {
                try? await Task.sleep(for: .seconds(2))
                Notifier().postStatusChange(
                    sessionName: "default",
                    agentName: "opencode",
                    title: "Test notification from SheepBell",
                    status: .blocked
                )
            }
        }
    }

    var body: some Scene {
        MenuBarExtra("SheepBell", systemImage: store.aggregateSymbol) {
            MenuView()
        }
        .menuBarExtraStyle(.window)
        .environment(store)

        Settings {
            SettingsView()
        }
    }
}
