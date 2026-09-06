import SwiftUI

/// Hand-drawn HerdrBell artwork living in
/// `Sources/Resources/Assets.xcassets/StatusIcons/` (template images).
/// Every asset carries an SF Symbol fallback so the scheme stays fully
/// functional before the artwork is imported.
struct CustomIconScheme: IconScheme {
    let id = "custom"
    let displayNameKey = "icon.scheme.custom"

    func appearance(for status: AgentStatus) -> StatusAppearance {
        switch status {
        case .blocked:
            StatusAppearance(icon: .asset(name: "status-blocked", fallback: "hand.raised.fill"), color: .red)
        case .working:
            StatusAppearance(icon: .asset(name: "status-working", fallback: "arrow.triangle.2.circlepath"), color: .blue)
        case .done:
            StatusAppearance(icon: .asset(name: "status-done", fallback: "checkmark.circle.fill"), color: .green)
        case .idle:
            StatusAppearance(icon: .asset(name: "status-idle", fallback: "circle.fill"), color: .gray)
        case .unknown:
            StatusAppearance(icon: .asset(name: "status-unknown", fallback: "questionmark.circle"), color: .gray)
        }
    }

    func aggregateIcon(for statuses: some Sequence<AgentStatus>) -> StatusIcon {
        let set = Set(statuses)
        if set.contains(.blocked) { return appearance(for: .blocked).icon }
        if set.contains(.working) { return appearance(for: .working).icon }
        if set.contains(.done) { return appearance(for: .done).icon }
        return idleAggregateIcon
    }

    var idleAggregateIcon: StatusIcon {
        .asset(name: "aggregate-idle", fallback: "circle.grid.2x2")
    }

    var disconnectedIcon: StatusIcon {
        .asset(name: "aggregate-disconnected", fallback: "circle.slash")
    }

    var focusedMarkerIcon: StatusIcon {
        .asset(name: "marker-focused", fallback: "cursorarrow.rays")
    }

    var emptyStateIcon: StatusIcon { disconnectedIcon }
}
