import Foundation
import Observation

@MainActor
@Observable
final class HerdrStore {
    struct SessionView: Identifiable, Sendable {
        let name: String
        var agents: [AgentItem]
        var connected: Bool

        var id: String { name }
    }

    private(set) var sessions: [SessionView] = []

    @ObservationIgnored private var clients: [String: HerdrSessionClient] = [:]
    @ObservationIgnored private let discovery = SessionDiscovery()
    @ObservationIgnored private let notifier = Notifier()
    @ObservationIgnored private var started = false

    var visibleSessions: [SessionView] {
        sessions.filter(\.connected).sorted { $0.name < $1.name }
    }

    var hasConnections: Bool {
        !visibleSessions.isEmpty
    }

    var aggregateSymbol: String {
        if visibleSessions.isEmpty { return "circle.slash" }
        let statuses = visibleSessions.flatMap { $0.agents.map(\.status) }
        if statuses.contains(.blocked) { return "exclamationmark.octagon.fill" }
        if statuses.contains(.working) { return "arrow.triangle.2.circlepath" }
        if statuses.contains(.done) { return "checkmark.circle.fill" }
        return "circle.grid.2x2"
    }

    func start() {
        guard !started else { return }
        started = true
        discovery.onChange = { [weak self] found in
            Task { @MainActor [weak self] in
                await self?.syncClients(with: found)
            }
        }
        discovery.start()
        if ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] == nil {
            Task { [notifier] in
                await notifier.requestAuthorization()
            }
        }
    }

    func stop() {
        guard started else { return }
        started = false
        discovery.stop()
        for client in clients.values {
            Task { await client.stop() }
        }
        clients.removeAll()
        sessions.removeAll()
    }

    func focus(_ agent: AgentItem, in sessionName: String) {
        guard let client = clients[sessionName] else { return }
        Task {
            try? await client.focus(paneId: agent.paneId)
        }
    }

    private func syncClients(with found: [DiscoveredSession]) async {
        guard started else { return }
        let foundNames = Set(found.map(\.name))
        for (name, client) in clients where !foundNames.contains(name) {
            await client.stop()
            clients.removeValue(forKey: name)
            sessions.removeAll { $0.name == name }
        }
        for session in found where clients[session.name] == nil {
            let client = HerdrSessionClient(sessionName: session.name, socketPath: session.socketPath) { [weak self] event in
                Task { @MainActor [weak self] in
                    await self?.handle(event)
                }
            }
            clients[session.name] = client
            sessions.append(SessionView(name: session.name, agents: [], connected: false))
            await client.start()
        }
    }

    private func handle(_ event: HerdrSessionClient.ClientEvent) async {
        guard started else { return }
        switch event {
        case .connectionChanged(let name, let connected):
            if let index = sessions.firstIndex(where: { $0.name == name }) {
                sessions[index].connected = connected
            }
        case .agentsChanged(let name, let agents):
            if let index = sessions.firstIndex(where: { $0.name == name }) {
                sessions[index].agents = agents
                sessions[index].connected = true
            }
        case .statusChanged(let name, let paneId, let from, let to):
            guard NotificationPolicy.shouldNotify(from: from, to: to) else { break }
            guard let session = sessions.first(where: { $0.name == name }),
                  let agent = session.agents.first(where: { $0.paneId == paneId })
            else { break }
            notifier.postStatusChange(
                sessionName: name,
                agentName: agent.agent,
                title: agent.title,
                status: to
            )
        }
    }
}
