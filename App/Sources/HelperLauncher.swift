import Foundation
import AppKit

/// Launches the embedded background helper.
///
/// The helper is bundled inside the app at `Contents/Library/LoginItems`. The
/// app starts it whenever it launches, so the hourly check-in reminders stay
/// scheduled. (True at-login start would need a signed build + SMAppService;
/// on an unsigned build the helper can be added to Login Items manually.)
enum HelperLauncher {

    private static let helperBundleID = "com.chethankmurthy.STOICOS.Helper"

    static func launchIfNeeded() {
        let alreadyRunning = NSWorkspace.shared.runningApplications.contains {
            $0.bundleIdentifier == helperBundleID
        }
        guard !alreadyRunning else { return }

        let helperURL = Bundle.main.bundleURL
            .appendingPathComponent("Contents/Library/LoginItems/STOICHelper.app")
        guard FileManager.default.fileExists(atPath: helperURL.path) else { return }

        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = false
        NSWorkspace.shared.openApplication(at: helperURL,
                                           configuration: configuration,
                                           completionHandler: nil)
    }
}
