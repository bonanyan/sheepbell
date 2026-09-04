import SwiftUI

@main
struct HerdrBellApp: App {
    @State private var store: HerdrStore

    init() {
        let store = HerdrStore()
        _store = State(initialValue: store)
        store.start()
        if CommandLine.arguments.contains("--herdrbell-test-notification") {
            Task {
                try? await Task.sleep(for: .seconds(2))
                Notifier().postStatusChange(
                    sessionName: "default",
                    agentName: "opencode",
                    title: "Test notification from HerdrBell",
                    status: .blocked
                )
            }
        }
    }

    var body: some Scene {
        MenuBarExtra("HerdrBell", systemImage: store.aggregateSymbol) {
            MenuView()
        }
        .menuBarExtraStyle(.window)
        .environment(store)

        Settings {
            SettingsView()
        }
    }
}
