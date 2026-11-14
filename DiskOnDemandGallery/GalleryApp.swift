import SwiftUI

@main
struct GalleryApp: App {
    var body: some Scene {
        Window("Disk on Demand — Galerie SwiftUI", id: "gallery") {
            GalleryView()
        }
        .defaultSize(width: 756, height: 444)
    }
}
