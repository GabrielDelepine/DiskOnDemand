import AppKit
import SwiftUI

@MainActor
final class DiskMenuBar: NSObject, NSApplicationDelegate {
    private let preview = DiskPreview()
    private let popover = NSPopover()
    private var statusItem: NSStatusItem?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem = item
        item.button?.image = NSImage(systemSymbolName: "externaldrive", accessibilityDescription: "Disk on Demand")
        item.button?.image?.isTemplate = true
        item.button?.toolTip = "Disk on Demand"
        item.button?.target = self
        item.button?.action = #selector(togglePopover(_:))

        let controller = NSHostingController(rootView: DiskMenu(preview: preview))
        // AppKit owns the popover's size while the SwiftUI content changes.
        controller.sizingOptions = []
        popover.contentViewController = controller
        popover.behavior = .transient
    }

    @objc private func togglePopover(_ button: NSStatusBarButton) {
        if popover.isShown {
            popover.performClose(button)
            return
        }

        var size = DiskMenu.preferredSize
        if let screen = button.window?.screen {
            size.height = min(size.height, screen.visibleFrame.height - 24)
        }
        popover.contentSize = size
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
    }
}
