import AppKit
import SwiftUI

struct DiskMenu: View {
    static let preferredSize = CGSize(width: 380, height: 612)

    let preview: DiskPreview

    var body: some View {
        VStack(alignment: .leading, spacing: DiskLayout.spacing) {
            header

            ScrollView {
                diskList
            }
            .id(preview.scenario)

            Divider()
            Button("Quitter Disk on Demand") {
                NSApp.terminate(nil)
            }
            .padding(.horizontal, DiskLayout.inset)
        }
        .padding(.vertical, DiskLayout.inset)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: DiskLayout.spacing) {
            Text("Disques externes")
                .font(.title3.weight(.semibold))
                .accessibilityAddTraits(.isHeader)

            HStack(spacing: 2) {
                ForEach(DiskPreview.Scenario.allCases, id: \.self) { scenario in
                    let isSelected = preview.scenario == scenario
                    Button {
                        preview.select(scenario)
                    } label: {
                        Text(scenario.rawValue)
                            .foregroundStyle(isSelected ? Color.white : Color.primary)
                            .frame(maxWidth: .infinity, minHeight: 24)
                            .background(isSelected ? Color.accentColor : .clear, in: .rect(cornerRadius: 5))
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(isSelected ? .isSelected : [])
                }
            }
            .font(.subheadline)
            .background(Color(nsColor: .quaternaryLabelColor), in: .rect(cornerRadius: 5))
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Cas du prototype")
        }
        .padding(.horizontal, DiskLayout.inset)
    }

    private var diskList: some View {
        VStack(alignment: .leading, spacing: DiskLayout.spacing) {
            if preview.disks.isEmpty {
                DiskSurface {
                    EmptyDisksView()
                }
            }
            ForEach(preview.disks) { disk in
                DiskSurface {
                    DiskHeader(name: disk.name, autoMount: disk.autoMount, autoMountUpdate: disk.autoMountUpdate) {
                        preview.setAutoMount($0, for: disk.id)
                    }
                    ForEach(disk.volumes) { volume in
                        Divider()
                        VolumeRow(name: volume.name, state: volume.state) {
                            preview.toggleMount(diskID: disk.id, volumeID: volume.id)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, DiskLayout.inset)
    }
}
