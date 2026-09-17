import AppKit
import SpriteKit

final class GameView: SKView {
  var game: GameScene? { scene as? GameScene }
  override var acceptsFirstResponder: Bool { true }
  override func keyDown(with event: NSEvent) {
    if event.modifierFlags.contains(.command) {
      super.keyDown(with: event)
      return
    }
    game?.keyDown(event.keyCode)
  }
  override func keyUp(with event: NSEvent) { game?.keyUp(event.keyCode) }
  override func mouseMoved(with event: NSEvent) {
    guard let s = scene else { return }
    game?.mouse = s.convertPoint(fromView: convert(event.locationInWindow, from: nil))
    game?.mouseAim = true
  }
  override func mouseDragged(with event: NSEvent) { mouseMoved(with: event) }
  override func mouseDown(with event: NSEvent) {
    mouseMoved(with: event)
    game?.mouseHeld = true
  }
  override func mouseUp(with event: NSEvent) { game?.mouseHeld = false }
  override func rightMouseDown(with event: NSEvent) {
    mouseMoved(with: event)
    game?.keyDown(40)
  }
  override func rightMouseUp(with event: NSEvent) { game?.keyUp(40) }
}
final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
  var window: NSWindow!
  var gameView: GameView!
  func applicationDidFinishLaunching(_ notification: Notification) {
    let screen = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
    let w = min(CGFloat(1280), screen.width - 70)
    let h = w * 0.625
    window = NSWindow(
      contentRect: NSRect(x: 0, y: 0, width: w, height: h),
      styleMask: [.titled, .closable, .miniaturizable, .resizable], backing: .buffered, defer: false
    )
    window.title = "The Last Ember"
    window.minSize = NSSize(width: 960, height: 630)
    window.contentAspectRatio = NSSize(width: 16, height: 10)
    window.center()
    window.delegate = self
    window.backgroundColor = dark
    window.acceptsMouseMovedEvents = true
    gameView = GameView(frame: NSRect(x: 0, y: 0, width: w, height: h))
    gameView.preferredFramesPerSecond = 60
    gameView.ignoresSiblingOrder = false
    window.contentView = gameView
    let scene = GameScene(size: CGSize(width: 1280, height: 800))
    scene.scaleMode = .aspectFit
    gameView.presentScene(scene)
    window.makeKeyAndOrderFront(nil)
    NSApp.activate(ignoringOtherApps: true)
    let menu = NSMenu()
    let root = NSMenuItem()
    menu.addItem(root)
    let appMenu = NSMenu()
    appMenu.addItem(
      withTitle: "Quit The Last Ember", action: #selector(NSApplication.terminate(_:)),
      keyEquivalent: "q")
    root.submenu = appMenu
    NSApp.mainMenu = menu
  }
  func windowDidResignKey(_ notification: Notification) {
    guard let s = gameView.game else { return }
    s.keys.removeAll()
    s.mouseHeld = false
    if s.state == "play" { s.showPause() }
  }
  func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }
}
