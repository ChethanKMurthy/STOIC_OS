import AppKit

// STOIC OS background helper — a login-item agent.
//
// Its job is to keep hourly check-in reminders firing even when the main app
// is fully quit. Step 1 establishes the target as a minimal background agent;
// the scheduling logic and login-item registration are wired in later steps.

let helper = NSApplication.shared
helper.setActivationPolicy(.accessory)
helper.run()
