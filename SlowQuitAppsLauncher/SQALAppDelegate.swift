import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        let alreadyRunning = NSWorkspace.shared.runningApplications.contains {
            $0.bundleIdentifier == "com.dteoh.SlowQuitApps"
        }
        if !alreadyRunning {
            var path = Bundle.main.bundlePath as NSString
            for _ in 1...4 {
                path = path.deletingLastPathComponent as NSString
            }
            NSWorkspace.shared.launchApplication(path as String)
        }
    }
}
