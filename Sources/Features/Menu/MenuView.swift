import SwiftUI

struct MenuView: View {
    @Environment(HerdrStore.self) private var store
    @Environment(LocalizationManager.self) private var l10n
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
                Label(l10n.string("menu.configure"), systemImage: "gear")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
            }
            .buttonStyle(.plain)

            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                Label(l10n.string("menu.quit"), systemImage: "power")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
            }
            .buttonStyle(.plain)

            Text(verbatim: "SheepBell v\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?")")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .frame(maxWidth: .infinity)
                .padding(.bottom, 6)
        }
        .frame(width: 280)
    }

    @ViewBuilder
    private var emptyState: some View {
        HStack(spacing: 8) {
            Image(systemName: store.scheme.emptyStateSymbol)
                .foregroundStyle(.secondary)
            Text(store.sessions.isEmpty ? l10n.string("menu.noSessions") : l10n.string("menu.connecting"))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 8)
    }

    @ViewBuilder
    private func sessionSection(_ session: HerdrStore.SessionView) -> some View {
        Text(verbatim: session.name)
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 8)
            .padding(.top, 6)

        if session.agents.isEmpty {
            Text(l10n.string("menu.noAgents"))
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
                        let appearance = store.scheme.appearance(for: agent.status)
                        Image(systemName: appearance.symbol)
                            .foregroundStyle(appearance.color)
                            .frame(width: 16)
                        VStack(alignment: .leading, spacing: 0) {
                            Text(verbatim: agent.agent)
                                .lineLimit(1)
                            Text(verbatim: agent.title)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                        Spacer()
                        if agent.focused {
                            Image(systemName: store.scheme.focusedAgentSymbol)
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
