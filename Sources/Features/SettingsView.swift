import SwiftUI

struct SettingsView: View {
    @AppStorage(SettingsKeys.notificationsEnabled) private var notificationsEnabled = true
    @State private var launchAtLogin = LoginItem.isEnabled

    var body: some View {
        Form {
            Toggle("Notify when an agent becomes blocked or done", isOn: $notificationsEnabled)
            Toggle("Launch SheepBell at login", isOn: Binding(
                get: { launchAtLogin },
                set: { newValue in
                    if LoginItem.setEnabled(newValue) {
                        launchAtLogin = newValue
                    } else {
                        launchAtLogin = LoginItem.isEnabled
                    }
                }
            ))
        }
        .formStyle(.grouped)
        .frame(width: 380)
    }
}

enum SettingsKeys {
    static let notificationsEnabled = "notificationsEnabled"
}
