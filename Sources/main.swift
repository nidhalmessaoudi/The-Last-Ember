import AppKit

let app = NSApplication.shared
if CommandLine.arguments.contains("--self-test") {
  runTests()
  exit(0)
}
app.setActivationPolicy(.regular)
let delegate = AppDelegate()
app.delegate = delegate
app.run()
