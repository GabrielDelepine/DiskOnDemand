import SwiftUI

struct GalleryView: View {
    @State private var appearance: Appearance = .system

    var body: some View {
        ScrollView([.horizontal, .vertical]) {
            HStack(alignment: .top, spacing: 24) {
                VStack(alignment: .leading, spacing: DiskLayout.spacing) {
                    heading("Disques et volumes")
                    DiskExample(name: "Archives USB", initiallyAutoMounts: false) {
                        InteractiveVolume(name: "Archives", initialState: .unmounted)
                    }
                    DiskExample(name: "SSD Studio", initiallyAutoMounts: true) {
                        InteractiveVolume(name: "Photos", initialState: .mounted)
                        Divider()
                        InteractiveVolume(
                            name: "Rushes vidéo et exports des projets en cours",
                            initialState: .mounted
                        )
                    }
                }
                .frame(width: DiskLayout.width)

                VStack(alignment: .leading, spacing: DiskLayout.spacing) {
                    heading("États et retours")
                    DiskSurface {
                        VolumeRow(name: "Musique", state: .mounting, onAction: {})
                        Divider()
                        VolumeRow(name: "Bibliothèque", state: .unmounting, onAction: {})
                    }
                    DiskSurface {
                        InteractiveVolume(name: "Projets", initialState: .busy)
                    }
                    DiskSurface {
                        EmptyDisksView()
                    }
                }
                .frame(width: DiskLayout.width)
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .frame(minWidth: 400, minHeight: 300)
        .toolbar {
            ToolbarItem {
                Picker("Apparence", selection: $appearance) {
                    ForEach(Appearance.allCases) { option in
                        Text(option.title).tag(option)
                    }
                }
                .pickerStyle(.segmented)
            }
        }
        .preferredColorScheme(appearance.colorScheme)
    }

    private func heading(_ title: LocalizedStringKey) -> some View {
        Text(title)
            .font(.title3.weight(.semibold))
            .accessibilityAddTraits(.isHeader)
    }
}

private enum Appearance: CaseIterable, Identifiable {
    case system, light, dark

    var id: Self { self }

    var title: LocalizedStringKey {
        switch self {
        case .system: "Système"
        case .light: "Clair"
        case .dark: "Sombre"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}

private struct DiskExample<Volumes: View>: View {
    let name: String
    let volumes: Volumes
    @State private var autoMount: Bool

    init(name: String, initiallyAutoMounts: Bool, @ViewBuilder volumes: () -> Volumes) {
        self.name = name
        self.volumes = volumes()
        _autoMount = State(initialValue: initiallyAutoMounts)
    }

    var body: some View {
        DiskSurface {
            DiskHeader(name: name, autoMount: autoMount) { autoMount = $0 }
            Divider()
            volumes
        }
    }
}

private struct InteractiveVolume: View {
    let name: String
    @State private var state: VolumeState

    init(name: String, initialState: VolumeState) {
        self.name = name
        _state = State(initialValue: initialState)
    }

    var body: some View {
        VolumeRow(name: name, state: state) {
            state = state == .unmounted ? .mounting : .unmounting
        }
        .task(id: state) {
            let operation = state
            guard operation.showsProgress else { return }
            do {
                try await Task.sleep(for: .milliseconds(900))
            } catch {
                return
            }
            state = operation == .mounting ? .mounted : .unmounted
        }
    }
}

#Preview("Montage automatique désactivé") {
    DiskExample(name: "Archives USB", initiallyAutoMounts: false) {
        InteractiveVolume(name: "Archives", initialState: .unmounted)
    }
    .frame(width: DiskLayout.width)
    .padding()
}

#Preview("Volume occupé et liste vide — sombre") {
    VStack(spacing: DiskLayout.spacing) {
        DiskSurface {
            InteractiveVolume(name: "Projets", initialState: .busy)
        }
        DiskSurface {
            EmptyDisksView()
        }
    }
    .frame(width: DiskLayout.width)
    .padding()
    .preferredColorScheme(.dark)
}
