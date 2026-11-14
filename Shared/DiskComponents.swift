import AppKit
import SwiftUI

enum DiskLayout {
    static let width: CGFloat = 340
    static let inset: CGFloat = 12
    static let spacing: CGFloat = 8
    static let textSpacing: CGFloat = 4
}

struct DiskSurface<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 12)

        VStack(alignment: .leading, spacing: DiskLayout.spacing) {
            content
        }
        .padding(DiskLayout.inset)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(nsColor: .controlBackgroundColor), in: shape)
        .overlay {
            shape.strokeBorder(Color(nsColor: .separatorColor))
                .allowsHitTesting(false)
        }
    }
}

enum AutoMountUpdate: Equatable {
    case idle
    case pending(Bool)
    case failed

    var requestedValue: Bool? {
        guard case .pending(let enabled) = self else { return nil }
        return enabled
    }
}

struct DiskHeader: View {
    let name: String
    let autoMount: Bool
    var autoMountUpdate: AutoMountUpdate = .idle
    let onAutoMountChange: @MainActor @Sendable (Bool) -> Void

    private var isPending: Bool { autoMountUpdate.requestedValue != nil }

    var body: some View {
        VStack(alignment: .leading, spacing: DiskLayout.spacing) {
            Label(name, systemImage: "externaldrive")
                .font(.headline)
                .lineLimit(2)
                .accessibilityAddTraits(.isHeader)

            Toggle(isOn: Binding(
                get: { autoMountUpdate.requestedValue ?? autoMount },
                set: onAutoMountChange
            )) {
                HStack(spacing: DiskLayout.spacing) {
                    Text("Montage automatique")
                    Spacer(minLength: DiskLayout.spacing)
                    if isPending {
                        ProgressView()
                            .controlSize(.mini)
                            .accessibilityHidden(true)
                    } else {
                        Text(autoMount ? "Activé" : "Désactivé")
                            .foregroundStyle(.secondary)
                            .accessibilityHidden(true)
                    }
                }
                .font(.subheadline)
            }
            .toggleStyle(.switch)
            .controlSize(.regular)
            .disabled(isPending)
            .accessibilityLabel("Montage automatique de \(name)")
            .accessibilityHint(isPending ? "Modification en cours" : "")

            if autoMountUpdate == .failed {
                Label("Impossible de modifier le montage automatique.",
                      systemImage: "exclamationmark.triangle")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

enum VolumeState: Equatable {
    case mounted, unmounted, mounting, unmounting, busy

    var status: LocalizedStringKey {
        switch self {
        case .mounted, .busy: "Monté"
        case .unmounted: "Démonté"
        case .mounting: "Montage en cours…"
        case .unmounting: "Démontage en cours…"
        }
    }

    var showsProgress: Bool {
        self == .mounting || self == .unmounting
    }

    var isMounted: Bool {
        self == .mounted || self == .busy
    }

    var actionTitle: LocalizedStringKey {
        switch self {
        case .mounted, .unmounting, .busy: "Démonter"
        case .unmounted, .mounting: "Monter"
        }
    }

    var actionSymbol: String {
        switch self {
        case .mounted, .unmounting, .busy: "eject"
        case .unmounted, .mounting: "externaldrive.badge.plus"
        }
    }

    func accessibilityAction(for name: String) -> LocalizedStringKey {
        switch self {
        case .mounted, .unmounting, .busy: "Démonter \(name)"
        case .unmounted, .mounting: "Monter \(name)"
        }
    }
}

struct VolumeRow: View {
    let name: String
    let state: VolumeState
    let onAction: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: DiskLayout.spacing) {
            HStack(alignment: .center, spacing: DiskLayout.spacing) {
                HStack(alignment: .firstTextBaseline, spacing: DiskLayout.textSpacing) {
                    Group {
                        if state.showsProgress {
                            ProgressView()
                                .controlSize(.mini)
                        } else {
                            Image(systemName: state.isMounted ? "circle.fill" : "circle")
                                .font(.system(size: 7, weight: .semibold))
                                .foregroundStyle(state.isMounted ? Color.accentColor : .secondary)
                        }
                    }
                    .frame(width: 12)
                    .alignmentGuide(.firstTextBaseline) { $0[VerticalAlignment.center] + 4 }
                    .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: DiskLayout.textSpacing) {
                        Text(name)
                            .font(.body.weight(.medium))
                            .lineLimit(2)
                            .accessibilityValue(Text(state.status))
                        if state.showsProgress {
                            Text(state.status)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .accessibilityHidden(true)
                        }
                    }
                    .help(Text("\(name) · \(Text(state.status))"))
                }
                Spacer(minLength: DiskLayout.spacing)
                Button(action: onAction) {
                    Label {
                        Text(state.actionTitle)
                    } icon: {
                        Image(systemName: state.actionSymbol)
                            .foregroundStyle(state == .unmounted ? Color.accentColor : .primary)
                    }
                    .labelStyle(.titleAndIcon)
                }
                .buttonStyle(VolumeActionButtonStyle())
                .disabled(state.showsProgress)
                .accessibilityLabel(Text(state.accessibilityAction(for: name)))
            }

            if state == .busy {
                Label("Volume occupé. Fermez les fichiers ouverts avant de le démonter.",
                      systemImage: "exclamationmark.triangle")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .contain)
    }
}

private struct VolumeActionButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        let shape = RoundedRectangle(cornerRadius: 6)

        configuration.label
            .font(.system(size: 12, weight: .medium))
            .padding(.horizontal, 10)
            .frame(minWidth: 100, minHeight: 24)
            .background(configuration.isPressed ? Color.primary.opacity(0.08) : .clear, in: shape)
            .overlay {
                shape.strokeBorder(Color(nsColor: .separatorColor))
                    .allowsHitTesting(false)
            }
            .contentShape(shape)
            .opacity(isEnabled ? 1 : 0.5)
    }
}

struct EmptyDisksView: View {
    var body: some View {
        Label("Aucun disque externe connecté", systemImage: "externaldrive")
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, minHeight: 28, alignment: .leading)
    }
}
