import SwiftUI

struct StatusAppearance: Sendable, Equatable {
    let symbol: String
    let color: Color
}

/// A pluggable visual theme mapping agent statuses to icons and colors.
///
/// To add a new icon set:
/// 1. Create a struct conforming to `IconScheme`.
/// 2. Append it to `IconSchemeRegistry.all`.
/// Nothing else needs to change — the menu, menu bar aggregate icon,
/// and the Configure picker pick it up automatically.
protocol IconScheme: Sendable {
    /// Stable identifier persisted in UserDefaults (`SettingsKeys.iconSchemeID`).
    var id: String { get }

    /// Localization key for the human-readable scheme name.
    var displayNameKey: String { get }

    /// Menu row icon and tint for a single agent status.
    func appearance(for status: AgentStatus) -> StatusAppearance

    /// Menu bar symbol summarizing all agents across connected sessions.
    /// Default priority: blocked > working > done > idle.
    func aggregateSymbol(for statuses: some Sequence<AgentStatus>) -> String

    /// Menu bar symbol shown when everything is idle (after the settle debounce).
    var idleAggregateSymbol: String { get }

    /// Menu bar symbol shown when no herdr session is connected.
    var disconnectedSymbol: String { get }

    /// Menu row accessory marking the focused agent.
    var focusedAgentSymbol: String { get }

    /// Icon for the menu's empty/offline state row.
    var emptyStateSymbol: String { get }
}
