import AppKit
import Darwin

@main
enum BlackHoleBinApplication {
    @MainActor
    static func main() {
        if CommandLine.arguments.contains("--self-test") {
            Darwin.exit(Int32(SelfTest.run()))
        }

        let application = NSApplication.shared
        let delegate = AppDelegate()
        application.delegate = delegate
        application.setActivationPolicy(.accessory)
        application.run()
        withExtendedLifetime(delegate) {}
    }
}
