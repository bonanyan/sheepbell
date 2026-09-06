import SwiftUI

struct ClassicIconScheme: IconScheme {
    let id = "classic"
    let displayNameKey = "icon.scheme.classic"

    func appearance(for status: AgentStatus) -> StatusAppearance {
        switch status {
        case .blocked: StatusAppearance(symbol: "hand.raised.fill", color: .red)
        case .working: StatusAppearance(symbol: "arrow.triangle.2.circlepath", color: .blue)
        case .done: StatusAppearance(symbol: "checkmark.circle.fill", color: .green)
        case .idle: StatusAppearance(symbol: "circle.fill", color: .gray)
        case .unknown: StatusAppearance(symbol: "questionmark.circle", color: .gray)
        }
    }

    func aggregateSymbol(for statuses: some Sequence<AgentStatus>) -> String {
        let set = Set(statuses)
        if set.contains(.blocked) { return "exclamationmark.octagon.fill" }
        if set.contains(.working) { return "arrow.triangle.2.circlepath" }
        if set.contains(.done) { return "checkmark.circle.fill" }
        return idleAggregateSymbol
    }

    var idleAggregateSymbol: String { "circle.grid.2x2" }
    var disconnectedSymbol: String { "circle.slash" }
    var focusedAgentSymbol: String { "cursorarrow.rays" }
    var emptyStateSymbol: String { "circle.slash" }
}
