import Foundation
import Testing

@testable import SheepBell

@Test
func registryHasUniqueIdsAndResolvesDefaults() {
    let ids = IconSchemeRegistry.all.map(\.id)
    #expect(Set(ids).count == ids.count)
    #expect(IconSchemeRegistry.scheme(id: "does-not-exist").id == IconSchemeRegistry.default.id)
    #expect(IconSchemeRegistry.scheme(id: "classic").id == "classic")
}

@Test
func classicSchemeCoversEveryStatus() {
    let scheme = ClassicIconScheme()
    let statuses: [AgentStatus] = [.idle, .working, .blocked, .done, .unknown]
    for status in statuses {
        #expect(!scheme.appearance(for: status).symbol.isEmpty)
    }
    #expect(scheme.aggregateSymbol(for: [.idle, .working, .blocked, .done])
        == scheme.aggregateSymbol(for: [.blocked]))
    #expect(scheme.aggregateSymbol(for: [.idle, .working, .done])
        == scheme.aggregateSymbol(for: [.working]))
    #expect(scheme.aggregateSymbol(for: [.idle, .done])
        == scheme.aggregateSymbol(for: [.done]))
    #expect(scheme.aggregateSymbol(for: [.idle, .unknown]) == scheme.idleAggregateSymbol)
    #expect(scheme.aggregateSymbol(for: []) == scheme.idleAggregateSymbol)
}

@Test
func everySchemeDisplayNameKeyIsLocalizable() {
    for scheme in IconSchemeRegistry.all {
        #expect(!scheme.displayNameKey.isEmpty)
    }
}
