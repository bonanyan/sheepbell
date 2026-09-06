import Foundation
import Testing

@testable import SheepBell

private func makeAgent(_ status: AgentStatus) -> AgentItem {
    AgentItem(
        paneId: "w1:p1",
        workspaceId: "w1",
        agent: "opencode",
        title: "test",
        status: status,
        focused: false,
        cwd: nil
    )
}

private let scheme = ClassicIconScheme()

@MainActor
private func makeConnectedStore(settleDelay: TimeInterval) async -> HerdrStore {
    let store = HerdrStore(idleSettleDelay: settleDelay)
    store.enableForTesting()
    store.addSessionForTesting(name: "default")
    await store.handle(.connectionChanged(sessionName: "default", connected: true))
    return store
}

@Test @MainActor
func aggregateIconIgnoresIdleBlipsWhileWorking() async throws {
    let store = await makeConnectedStore(settleDelay: 0.4)
    await store.handle(.agentsChanged(sessionName: "default", agents: [makeAgent(.working)]))
    #expect(store.aggregateSymbol == scheme.aggregateSymbol(for: [AgentStatus.working]))

    await store.handle(.agentsChanged(sessionName: "default", agents: [makeAgent(.idle)]))
    #expect(store.aggregateSymbol == scheme.aggregateSymbol(for: [AgentStatus.working]))

    await store.handle(.agentsChanged(sessionName: "default", agents: [makeAgent(.working)]))
    #expect(store.aggregateSymbol == scheme.aggregateSymbol(for: [AgentStatus.working]))

    try await Task.sleep(for: .milliseconds(700))
    #expect(store.aggregateSymbol == scheme.aggregateSymbol(for: [AgentStatus.working]))
}

@Test @MainActor
func aggregateIconSettlesToIdleAfterSustainedIdle() async throws {
    let store = await makeConnectedStore(settleDelay: 0.3)
    await store.handle(.agentsChanged(sessionName: "default", agents: [makeAgent(.working)]))
    await store.handle(.agentsChanged(sessionName: "default", agents: [makeAgent(.idle)]))
    #expect(store.aggregateSymbol == scheme.aggregateSymbol(for: [AgentStatus.working]))

    try await Task.sleep(for: .milliseconds(600))
    #expect(store.aggregateSymbol == scheme.idleAggregateSymbol)
}

@Test @MainActor
func aggregateIconShowsBlockedAndDoneImmediately() async throws {
    let store = await makeConnectedStore(settleDelay: 5)
    await store.handle(.agentsChanged(sessionName: "default", agents: [makeAgent(.working)]))

    await store.handle(.agentsChanged(sessionName: "default", agents: [makeAgent(.blocked)]))
    #expect(store.aggregateSymbol == scheme.aggregateSymbol(for: [AgentStatus.blocked]))

    await store.handle(.agentsChanged(sessionName: "default", agents: [makeAgent(.done)]))
    #expect(store.aggregateSymbol == scheme.aggregateSymbol(for: [AgentStatus.done]))
}

@Test @MainActor
func aggregateIconDisconnectIsImmediate() async throws {
    let store = await makeConnectedStore(settleDelay: 5)
    await store.handle(.agentsChanged(sessionName: "default", agents: [makeAgent(.working)]))
    #expect(store.aggregateSymbol == scheme.aggregateSymbol(for: [AgentStatus.working]))

    await store.handle(.connectionChanged(sessionName: "default", connected: false))
    #expect(store.aggregateSymbol == scheme.disconnectedSymbol)
}
