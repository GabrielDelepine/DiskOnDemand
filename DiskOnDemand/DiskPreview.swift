import Foundation
import Observation

@MainActor
@Observable
final class DiskPreview {
    private(set) var scenario: Scenario = .disks
    var disks = Scenario.disks.makeDisks()

    func select(_ scenario: Scenario) {
        guard self.scenario != scenario else { return }
        self.scenario = scenario
        disks = scenario.makeDisks()
    }

    func setAutoMount(_ enabled: Bool, for diskID: Disk.ID) {
        guard let index = disks.firstIndex(where: { $0.id == diskID }),
              disks[index].autoMount != enabled,
              disks[index].autoMountUpdate.requestedValue == nil
        else { return }

        disks[index].autoMountUpdate = .pending(enabled)
        Task {
            try? await Task.sleep(for: .milliseconds(1500))
            guard let index = disks.firstIndex(where: { $0.id == diskID }) else { return }

            switch disks[index].simulatedAutoMountResult {
            case .success:
                disks[index].autoMount = enabled
                disks[index].autoMountUpdate = .idle
            case .cancelled:
                disks[index].autoMountUpdate = .idle
            case .failure:
                disks[index].autoMountUpdate = .failed
            }
        }
    }

    func toggleMount(diskID: Disk.ID, volumeID: Volume.ID) {
        guard let diskIndex = disks.firstIndex(where: { $0.id == diskID }),
              let volumeIndex = disks[diskIndex].volumes.firstIndex(where: { $0.id == volumeID })
        else { return }

        let state = disks[diskIndex].volumes[volumeIndex].state
        guard !state.showsProgress else { return }
        let isMounting = state == .unmounted
        disks[diskIndex].volumes[volumeIndex].state = isMounting ? .mounting : .unmounting

        Task {
            try? await Task.sleep(for: .milliseconds(900))
            guard let diskIndex = disks.firstIndex(where: { $0.id == diskID }),
                  let volumeIndex = disks[diskIndex].volumes.firstIndex(where: { $0.id == volumeID })
            else { return }
            disks[diskIndex].volumes[volumeIndex].state = isMounting ? .mounted : .unmounted
        }
    }

    struct Disk: Identifiable {
        let id = UUID()
        let name: String
        var autoMount = true
        var autoMountUpdate: AutoMountUpdate = .idle
        var simulatedAutoMountResult: AutoMountResult = .success
        var volumes: [Volume]
    }

    enum AutoMountResult {
        case success, cancelled, failure
    }

    struct Volume: Identifiable {
        let id = UUID()
        let name: String
        var state: VolumeState = .mounted
    }

    enum Scenario: String, CaseIterable {
        case disks = "Disques"
        case operations = "En cours"
        case many = "Liste longue"
        case empty = "Vide"

        func makeDisks() -> [Disk] {
            switch self {
            case .disks:
                [
                    Disk(name: "Archives USB", autoMount: false, volumes: [
                        Volume(name: "Archives", state: .unmounted)
                    ]),
                    Disk(name: "SSD Studio", volumes: [
                        Volume(name: "Photos"),
                        Volume(name: "Rushes vidéo et exports des projets en cours", state: .unmounted)
                    ]),
                    Disk(name: "Sauvegarde USB", autoMount: false, volumes: [
                        Volume(name: "Projets", state: .busy)
                    ])
                ]
            case .operations:
                [
                    Disk(name: "SSD Média", autoMount: false, volumes: [
                        Volume(name: "Musique", state: .mounting),
                        Volume(name: "Bibliothèque", state: .unmounting)
                    ]),
                    Disk(name: "Archives USB · Annulation simulée", autoMount: false,
                         simulatedAutoMountResult: .cancelled, volumes: [
                            Volume(name: "Archives", state: .unmounted)
                         ]),
                    Disk(name: "Sauvegarde USB · Échec simulé",
                         simulatedAutoMountResult: .failure, volumes: [
                            Volume(name: "Sauvegarde")
                         ])
                ]
            case .many:
                (1...10).map { index in
                    Disk(name: "Disque de sauvegarde \(index)", autoMount: index.isMultiple(of: 2), volumes: [
                        Volume(name: "Sauvegarde \(index)", state: index.isMultiple(of: 3) ? .unmounted : .mounted)
                    ])
                }
            case .empty:
                []
            }
        }
    }
}
