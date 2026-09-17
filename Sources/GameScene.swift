import AppKit
import Foundation
import SpriteKit

final class GameScene: SKScene {
  let world = SKNode()
  let ground = SKNode()
  let actors = SKNode()
  let effects = SKNode()
  let hud = SKNode()
  let overlay = SKNode()
  let audio = Sound()
  var player = Fighter(kind: 0, player: true)
  var enemies: [Fighter] = []
  var boss: Fighter?
  var hazards: [Hazard] = []
  var projectiles: [Projectile] = []
  var keys = Set<UInt16>()
  var pressed = Set<UInt16>()
  var mouse = CGPoint(x: 640, y: 500)
  var mouseHeld = false
  var mouseAim = false
  var state = "title"
  var previousState = "play"
  var save = SaveData()
  var lastTime: TimeInterval = 0
  var time: CGFloat = 0
  var flasks = 3
  var staminaDelay: CGFloat = 0
  var transition: CGFloat = 0
  var deathTime: CGFloat = 0
  var bossIntro: CGFloat = 0
  var roomCleared = false
  var sentriesDead = false
  var blood: SKNode?
  var bloodValue = 0
  var bloodPoint = CGPoint.zero
  var shrine = CGPoint(x: 640, y: 176)
  var gate = CGPoint(x: 640, y: 610)
  var messageTime: CGFloat = 0
  var notification = SKNode()
  var interactText = SKLabelNode()
  var bossTitle = SKLabelNode()
  var bossBar = SKShapeNode()
  var postureBar = SKShapeNode()
  var hpFill = SKShapeNode()
  var stFill = SKShapeNode()
  var flaskLabel = SKLabelNode()
  var emberLabel = SKLabelNode()
  var regionLabel = SKLabelNode()
  var bossHUD = SKNode()
  var cameraShake: CGFloat = 0
  var shakeAmount: CGFloat = 0
  var riposte: CGFloat = 0
  var banner = SKNode()
  var hint = SKLabelNode()
  var region: Region { regions[min(save.chapter, 4)] }
  var damage: CGFloat { (save.easy ? 30 : 27) + CGFloat(save.blade) * 6 }
  var maxHP: CGFloat { 120 + CGFloat(save.vitality) * 25 }
  var maxFlasks: Int { 3 + save.flask }
  var moveSpeed: CGFloat { 210 }
  var accent: NSColor { hex(region.color) }
  let saveURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
    .first!.appendingPathComponent("TheLastEmber/save.json")
  override func didMove(to view: SKView) {
    backgroundColor = dark
    addChild(world)
    world.addChild(ground)
    world.addChild(actors)
    world.addChild(effects)
    ground.zPosition = -100
    effects.zPosition = 600
    addChild(hud)
    hud.zPosition = 1000
    addChild(overlay)
    overlay.zPosition = 2000
    load()
    buildRoom()
    buildHUD()
    showTitle()
    view.window?.makeFirstResponder(view)
  }
  func load() {
    if let d = try? Data(contentsOf: saveURL),
      let s = try? JSONDecoder().decode(SaveData.self, from: d)
    {
      save = s
      save.chapter = min(4, max(0, save.chapter))
      bloodValue = save.lostEmbers
      bloodPoint = CGPoint(x: save.lostX, y: save.lostY)
    }
  }
  func persist() {
    save.lostEmbers = bloodValue
    save.lostX = bloodPoint.x
    save.lostY = bloodPoint.y
    if CommandLine.arguments.contains("--self-test") { return }
    try? FileManager.default.createDirectory(
      at: saveURL.deletingLastPathComponent(), withIntermediateDirectories: true)
    if let d = try? JSONEncoder().encode(save) { try? d.write(to: saveURL, options: .atomic) }
  }
  func keyDown(_ k: UInt16) {
    if k == 38 || k == 40 || k == 37 { mouseAim = false }
    if !keys.contains(k) { pressed.insert(k) }
    keys.insert(k)
  }
  func keyUp(_ k: UInt16) { keys.remove(k) }
  func edge(_ k: UInt16) -> Bool { pressed.contains(k) }
  func down(_ k: UInt16) -> Bool { keys.contains(k) }
}
