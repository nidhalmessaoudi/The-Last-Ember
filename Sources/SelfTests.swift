import AppKit
import Foundation
import SpriteKit

func runTests() {
  let g = GameScene(size: CGSize(width: 1280, height: 800))
  g.addChild(g.world)
  g.world.addChild(g.ground)
  g.world.addChild(g.actors)
  g.world.addChild(g.effects)
  g.addChild(g.hud)
  g.addChild(g.overlay)
  g.buildRoom()
  g.buildHUD()
  g.state = "play"
  var checks = 0
  func check(_ b: Bool, _ name: String) {
    if !b {
      print("FAIL: \(name)")
      exit(1)
    }
    checks += 1
    print("PASS: \(name)")
  }
  check(g.enemies.count == 2, "opening sentries")
  let target = g.enemies[0]
  g.player.pos = target.pos - CGPoint(x: 65, y: 0)
  g.player.facing = CGPoint(x: 1, y: 0)
  let old = target.hp
  g.strike(false)
  check(target.hp < old, "melee deals damage")
  g.player.stamina = 100
  g.dodge()
  let health = g.player.hp
  g.hurtPlayer(20, target.pos)
  check(g.player.hp == health && g.player.stamina == 75, "dodge invulnerability and stamina cost")
  g.player.invuln = 0
  g.player.action = 0
  g.player.stamina = 100
  g.parry()
  g.hurtPlayer(20, target.pos, true, target)
  check(g.player.hp == health && target.stagger > 0, "perfect parry staggers sentry")
  g.player.action = 0
  g.player.invuln = 0
  g.player.hp = 50
  g.flasks = 3
  g.heal()
  for _ in 0..<60 {
    g.lastTime += 1.0 / 60
    g.update(g.lastTime + 1.0 / 60)
  }
  check(g.player.hp > 50 && g.flasks == 2, "healing resolves and consumes flask")
  g.save.embers = 100
  g.player.invuln = 0
  g.hurtPlayer(999, target.pos)
  check(g.state == "dead" && g.bloodValue == 100 && g.save.embers == 0, "death drops held embers")
  g.respawn()
  check(
    g.player.hp == g.maxHP && g.blood != nil, "respawn restores player and leaves recovery ember")
  g.player.pos = g.bloodPoint
  g.update(g.lastTime + 0.02)
  check(g.save.embers == 100 && g.bloodValue == 0, "lost embers recover")
  g.rest()
  g.pressed = [18]
  g.input()
  g.pressed = []
  check(
    g.save.vitality == 1 && g.save.embers == 30, "shrine upgrade applies and charges exact price")
  g.state = "play"
  g.overlay.removeAllChildren()
  for chapter in 0..<5 {
    g.save.chapter = chapter
    g.save.cleared = false
    g.buildRoom()
    g.buildHUD()
    for e in g.enemies {
      e.dead = true
      e.node.removeFromParent()
    }
    g.beginBoss()
    g.bossIntro = 0
    let b = g.boss!
    g.player.invuln = 10000
    g.player.pos = CGPoint(x: 640, y: 400)
    for _ in 0..<15 {
      b.action = 0
      b.cooldown = 0
      g.decide(b)
      for _ in 0..<160 {
        g.updateEnemy(b, 1.0 / 60)
        g.updateHazards(1.0 / 60)
        g.updateProjectiles(1.0 / 60)
      }
      b.hp = b.maxHP * 0.45
    }
    check(b.phase == 2, "guardian \(chapter+1) patterns and second phase")
    g.hurtEnemy(b, 10000, 100)
    check(
      g.save.cleared && g.roomCleared && g.boss == nil,
      "guardian \(chapter+1) defeat and progression")
  }
  g.showVictory()
  check(g.save.won && g.state == "victory", "ending reachable")
  let encoded = try! JSONEncoder().encode(g.save)
  let decoded = try! JSONDecoder().decode(SaveData.self, from: encoded)
  check(decoded.chapter == 4 && decoded.won, "save roundtrip")
  let legacySave = Data(#"{"chapter":2,"embers":77}"#.utf8)
  let migrated = try! JSONDecoder().decode(SaveData.self, from: legacySave)
  check(
    migrated.chapter == 2 && migrated.embers == 77 && migrated.lostEmbers == 0,
    "older saves migrate with safe defaults")
  g.state = "play"
  g.showPause()
  g.pressed = [46]
  g.input()
  check(g.state == "pause" && g.previousState == "play" && !g.audio.enabled, "pause sound toggle")
  print("ALL \(checks) GAMEPLAY CHECKS PASSED")
  let preview = SKView(frame: NSRect(x: 0, y: 0, width: 1280, height: 800))
  preview.ignoresSiblingOrder = false
  let visual = GameScene(size: CGSize(width: 1280, height: 800))
  preview.presentScene(visual)
  func capture(_ name: String) {
    if let tex = preview.texture(from: visual) {
      let cg = tex.cgImage()
      let bitmap = NSBitmapImageRep(cgImage: cg)
      if let data = bitmap.representation(using: .png, properties: [:]) {
        try? data.write(to: URL(fileURLWithPath: "/tmp/last-ember-\(name).png"))
        print("Rendered \(name)")
      }
    }
  }
  capture("title")
  visual.start()
  visual.banner.removeFromParent()
  visual.beginBoss()
  visual.banner.removeFromParent()
  visual.update(0.02)
  capture("combat")

}
