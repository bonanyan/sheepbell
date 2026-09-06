import SwiftUI

struct ClassicIconScheme: IconScheme {
    let id = "classic"
    let displayNameKey = "icon.scheme.classic"

    func appearance(for status: AgentStatus) -> StatusAppearance {
        switch status {
        case .blocked: StatusAppearance(icon: .systemSymbol("hand.raised.fill"), color: .red)
        case .working: StatusAppearance(icon: .systemSymbol("arrow.triangle.2.circlepath"), color: .blue)
        case .done: StatusAppearance(icon: .systemSymbol("checkmark.circle.fill"), color: .green)
        case .idle: StatusAppearance(icon: .systemSymbol("circle.fill"), color: .gray)
        case .unknown: StatusAppearance(icon: .systemSymbol("questionmark.circle"), color: .gray)
        }
    }

    func aggregateIcon(for statuses: some Sequence<AgentStatus>) -> StatusIcon {
        let set = Set(statuses)
        if set.contains(.blocked) { return .systemSymbol("exclamationmark.octagon.fill") }
        if set.contains(.working) { return .systemSymbol("arrow.triangle.2.circlepath") }
        if set.contains(.done) { return .systemSymbol("checkmark.circle.fill") }
        return idleAggregateIcon
    }

    var idleAggregateIcon: StatusIcon { .systemSymbol("circle.grid.2x2") }
    var disconnectedIcon: StatusIcon { .systemSymbol("circle.slash") }
    var focusedMarkerIcon: StatusIcon { .systemSymbol("cursorarrow.rays") }
    var emptyStateIcon: StatusIcon { .systemSymbol("circle.slash") }
}
