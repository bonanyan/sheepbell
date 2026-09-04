import SwiftUI

extension AgentStatus {
    var symbol: String {
        switch self {
        case .blocked: "hand.raised.fill"
        case .working: "arrow.triangle.2.circlepath"
        case .done: "checkmark.circle.fill"
        case .idle: "circle.fill"
        case .unknown: "questionmark.circle"
        }
    }

    var color: Color {
        switch self {
        case .blocked: .red
        case .working: .blue
        case .done: .green
        case .idle: .gray
        case .unknown: .gray
        }
    }
}
