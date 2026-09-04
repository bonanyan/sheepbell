import SwiftUI

struct MenuView: View {
    @Environment(HerdrStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            if store.visibleSessions.isEmpty {
                emptyState
                    .padding(.vertical, 12)
            } else {
                ForEach(store.visibleSessions) { session in
                    sessionSection(session)
                }
            }

            Divider().padding(.vertical, 4)

            SettingsLink {
                Label("Settings…", systemImage: "gear")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
            }
            .buttonStyle(.plain)

            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                Label("Quit SheepBell", systemImage: "power")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
            }
            .buttonStyle(.plain)
            .padding(.bottom, 6)
        }
        .frame(width: 280)
    }

    @ViewBuilder
    private var emptyState: some View {
        HStack(spacing: 8) {
            Image(systemName: "circle.slash")
                .foregroundStyle(.secondary)
            Text(store.sessions.isEmpty ? "No herdr sessions found" : "Connecting…")
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 8)
    }

    @ViewBuilder
    private func sessionSection(_ session: HerdrStore.SessionView) -> some View {
        Text(session.name)
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 8)
            .padding(.top, 6)

        if session.agents.isEmpty {
            Text("No agents")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
        } else {
            ForEach(session.agents) { agent in
                Button {
                    store.focus(agent, in: session.name)
                    dismiss()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: agent.status.symbol)
                            .foregroundStyle(agent.status.color)
                            .frame(width: 16)
                        VStack(alignment: .leading, spacing: 0) {
                            Text(agent.agent)
                                .lineLimit(1)
                            Text(agent.title)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                        Spacer()
                        if agent.focused {
                            Image(systemName: "cursorarrow.rays")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .contentShape(Rectangle())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                }
                .buttonStyle(.plain)
                .help(agent.title)
            }
        }
    }
}
