import Foundation
import UserNotifications

enum NotificationPolicy: Sendable {
    static func shouldNotify(from: AgentStatus?, to: AgentStatus) -> Bool {
        guard to == .blocked || to == .done else { return false }
        return from != to
    }
}

final class Notifier: @unchecked Sendable {
    private var center: UNUserNotificationCenter {
        UNUserNotificationCenter.current()
    }

    func requestAuthorization() async {
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .notDetermined else { return }
        _ = try? await center.requestAuthorization(options: [.alert, .sound])
    }

    func postStatusChange(sessionName: String, agentName: String, title: String, status: AgentStatus) {
        guard status == .blocked || status == .done else { return }
        let enabled = UserDefaults.standard.object(forKey: SettingsKeys.notificationsEnabled) as? Bool ?? true
        guard enabled else { return }
        let content = UNMutableNotificationContent()
        content.title = status == .blocked
            ? "Agent blocked: \(agentName)"
            : "Agent done: \(agentName)"
        content.body = title.isEmpty ? "session \(sessionName)" : title
        content.sound = .default
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        center.add(request, withCompletionHandler: nil)
    }
}
