import AppKit

@main
struct DiskOnDemandApp {
    @MainActor
    static func main() {
        let app = NSApplication.shared
        let delegate = DiskMenuBar()
        app.delegate = delegate
        withExtendedLifetime(delegate) {
            app.run()
        }
    }
}
