import AppKit
import SpriteKit

extension GameScene {
  func clearCombat() {
    for e in enemies { e.node.removeFromParent() }
    enemies = []
    boss = nil
    for h in hazards { h.node.removeFromParent() }
    hazards = []
    for p in projectiles { p.node.removeFromParent() }
    projectiles = []
    effects.removeAllChildren()
    bossHUD.isHidden = true
  }
  func buildRoom() {
    clearCombat()
    ground.removeAllChildren()
    actors.removeAllChildren()
    world.position = .zero
    let c = accent
    at(rect(1280, 800, hex(region.floor)), 640, 400, ground)
    // Layered stone court, with a luminous inlaid combat circle.
    at(rect(1136, 584, hex(0x080e15), 24), 640, 384, ground)
    at(rect(1118, 566, hex(region.floor), 20), 640, 387, ground)
    var rng: UInt64 = UInt64(save.chapter + 11) * 234567
    func random() -> CGFloat {
      rng = rng &* 6_364_136_223_846_793_005 &+ 1
      return CGFloat((rng >> 33) % 10000) / 10000
    }
    for row in 0..<17 {
      for col in 0..<23 {
        let x = CGFloat(col) * 50 + 82 + (row % 2 == 0 ? 0 : 25)
        let y = CGFloat(row) * 32 + 111
        if x > 1202 { continue }
        let v = random()
        let tile = rect(
          47, 29,
          hex(region.floor).blended(withFraction: CGFloat(v * 0.1), of: v > 0.5 ? .white : .black)!,
          3)
        tile.position = CGPoint(x: x, y: y)
        ground.addChild(tile)
        if v > 0.77 {
          let p = CGMutablePath()
          p.move(to: CGPoint(x: -13, y: 8))
          p.addLine(to: CGPoint(x: -4, y: 0))
          p.addLine(to: CGPoint(x: -7, y: -9))
          tile.addChild(shape(p, .clear, hex(0x090e14, 0.45), 1))
        }
      }
    }
    let ellipse = SKShapeNode(ellipseOf: CGSize(width: 620, height: 420))
    ellipse.strokeColor = c.withAlphaComponent(0.18)
    ellipse.lineWidth = 2
    ellipse.position = CGPoint(x: 640, y: 404)
    ground.addChild(ellipse)
    let ellipse2 = SKShapeNode(ellipseOf: CGSize(width: 650, height: 440))
    ellipse2.strokeColor = c.withAlphaComponent(0.1)
    ellipse2.position = CGPoint(x: 640, y: 404)
    ground.addChild(ellipse2)
    for i in 0..<16 {
      let a = CGFloat(i) * pi / 8
      let p = CGPoint(x: 640 + cos(a) * 323, y: 404 + sin(a) * 216)
      let rune = label(["✧", "Ⅰ", "╳", "◇"][i % 4], 14, c.withAlphaComponent(0.3))
      rune.position = p
      ground.addChild(rune)
    }
    // Dark silhouettes frame the playable court.
    for side in 0..<2 {
      for i in 0..<7 {
        let x: CGFloat = side == 0 ? CGFloat(18 + i % 2 * 27) : CGFloat(1240 + i % 2 * 27)
        let y = CGFloat(i) * 104 + 83
        let p = poly(
          [CGPoint(x: -40, y: 0), CGPoint(x: 0, y: 110 + random() * 50), CGPoint(x: 40, y: 0)],
          hex(0x090f17))
        p.position = CGPoint(x: x, y: y)
        ground.addChild(p)
      }
    }
    for x: CGFloat in [155, 1125] {
      for y: CGFloat in [220, 460, 632] {
        let base = rect(52, 24, hex(0x0a1119), 5)
        at(base, x, y - 10, ground)
        at(rect(32, 63, hex(0x363b40), 4), x, y + 20, ground)
        at(rect(43, 12, hex(0x555453), 2), x, y + 50, ground)
        at(rect(38, 8, hex(0x161e26)), x, y - 8, ground)
        at(rect(2, 43, hex(0x797466, 0.35)), x - 9, y + 23, ground)
        at(glow(90, c), x, y + 63, ground)
        at(
          poly(
            [
              CGPoint(x: -6, y: 0), CGPoint(x: -8, y: 11), CGPoint(x: 0, y: 26),
              CGPoint(x: 5, y: 12), CGPoint(x: 6, y: 2),
            ], c), x, y + 56, ground)
      }
    }
    for _ in 0..<44 {
      let x = 95 + random() * 1090
      let y = 110 + random() * 543
      if dist(CGPoint(x: x, y: y), CGPoint(x: 640, y: 390)) < 235 { continue }
      let r = 3 + random() * 7
      let rock = poly(
        [
          CGPoint(x: -r, y: 0), CGPoint(x: -r * 0.4, y: r), CGPoint(x: r * 0.6, y: r * 0.8),
          CGPoint(x: r, y: 0),
        ], hex(0x687074, 0.18))
      rock.position = CGPoint(x: x, y: y)
      ground.addChild(rock)
    }
    if save.chapter == 1 {
      for _ in 0..<22 {
        let x = random() > 0.5 ? 200 + random() * 110 : 970 + random() * 110
        let y = 180 + random() * 410
        let p = CGMutablePath()
        p.move(to: CGPoint(x: 0, y: 0))
        p.addCurve(
          to: CGPoint(x: random() * 50 - 25, y: 65), control1: CGPoint(x: -40, y: 25),
          control2: CGPoint(x: 40, y: 40))
        let v = shape(p, .clear, c.withAlphaComponent(0.3), 3)
        at(v, x, y, ground)
      }
    }
    if save.chapter == 2 {
      for _ in 0..<16 {
        let puddle = SKShapeNode(
          ellipseOf: CGSize(width: 60 + random() * 150, height: 18 + random() * 40))
        puddle.fillColor = hex(0x548da6, 0.12)
        puddle.strokeColor = c.withAlphaComponent(0.13)
        at(puddle, 240 + random() * 800, 180 + random() * 410, ground)
      }
    }
    if save.chapter == 3 {
      for _ in 0..<32 {
        at(
          glow(15 + random() * 18, hex(0xff6538)), 210 + random() * 860, 150 + random() * 470,
          ground)
      }
    }
    if save.chapter == 4 {
      at(glow(300, gold), 640, 652, ground)
      for i in 0..<15 {
        let p = CGMutablePath()
        p.move(to: CGPoint(x: 640, y: 700))
        p.addLine(to: CGPoint(x: 200 + CGFloat(i) * 64, y: 115))
        ground.addChild(shape(p, .clear, gold.withAlphaComponent(0.06), 2))
      }
    }
    let steps = SKNode()
    for i in 0..<4 {
      at(
        rect(CGFloat(170 - i * 20), 12, hex(0x61615e, CGFloat(0.2 + Double(i) * 0.07))), 0,
        CGFloat(i * 10), steps)
    }
    at(steps, 640, 602, ground)
    at(rect(68, 98, hex(0x10151c), 25), 640, 661, ground)
    at(circle(30, .clear, c, 2), 640, 659, ground)
    at(label("✧", 38, c), 640, 658, ground)
    at(glow(110, c), 640, 644, ground)
    let fire = SKNode()
    at(SKShapeNode(ellipseOf: CGSize(width: 65, height: 25)), 0, -7, fire)
    at(rect(43, 8, hex(0x675950), 3), 0, 0, fire)
    at(rect(30, 7, hex(0x40362e), 2), 4, 7, fire)
    at(glow(130, gold), 0, 10, fire)
    let flame = poly(
      [
        CGPoint(x: -13, y: 5), CGPoint(x: -16, y: 21), CGPoint(x: -5, y: 33), CGPoint(x: 0, y: 52),
        CGPoint(x: 12, y: 30), CGPoint(x: 13, y: 11),
      ], gold)
    fire.addChild(flame)
    at(poly([CGPoint(x: -6, y: 8), CGPoint(x: 0, y: 31), CGPoint(x: 7, y: 10)], ivory), 0, 0, fire)
    flame.run(
      .repeatForever(
        .sequence([.scaleX(to: 0.78, duration: 0.17), .scaleX(to: 1.08, duration: 0.21)])))
    at(fire, shrine.x, shrine.y, ground)
    player = Fighter(kind: 0, player: true)
    player.maxHP = maxHP
    player.hp = maxHP
    player.pos = CGPoint(x: 640, y: 245)
    actors.addChild(player.node)
    flasks = maxFlasks
    roomCleared = save.cleared
    sentriesDead = save.cleared
    staminaDelay = 0
    bossIntro = 0
    if !save.cleared { spawnSentries() }
    if bloodValue > 0 { makeBlood() }
    for _ in 0..<35 {
      let mote = circle(random() * 1.6 + 0.6, c.withAlphaComponent(0.4))
      mote.position = CGPoint(x: random() * 1280, y: random() * 800)
      mote.zPosition = 90
      ground.addChild(mote)
      mote.run(
        .repeatForever(
          .sequence([
            .group([
              .moveBy(x: random() * 40 - 20, y: 70, duration: 4 + Double(random() * 5)),
              .fadeOut(withDuration: 7),
            ]),
            .run { [weak mote] in
              mote?.position.y -= 70
              mote?.alpha = 1
            },
          ])))
    }
  }
  func spawnSentries() {
    for (i, p) in [CGPoint(x: 420, y: 405), CGPoint(x: 860, y: 460), CGPoint(x: 650, y: 505)]
      .enumerated()
    {
      if save.chapter == 0 && i == 2 { continue }
      let e = Fighter(kind: save.chapter)
      e.hp = 80 + CGFloat(save.chapter) * 15
      e.maxHP = e.hp
      e.pos = p
      e.cooldown = CGFloat(i) * 0.5 + 0.7
      enemies.append(e)
      actors.addChild(e.node)
    }
  }
  func makeBlood() {
    blood?.removeFromParent()
    let b = SKNode()
    b.addChild(glow(50, hex(0x86dad0)))
    b.addChild(circle(12, .clear, hex(0x91d8cc), 2))
    at(label("✧", 20, ivory), 0, 0, b)
    b.position = bloodPoint
    ground.addChild(b)
    blood = b
  }
}
