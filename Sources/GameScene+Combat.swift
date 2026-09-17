import AppKit
import SpriteKit

extension GameScene {
  func boonCount(_ n: Int) -> Int { save.boons.filter { $0 == n }.count }
  func input() {
    if edge(46) { audio.toggle() }
    if edge(3) { view?.window?.toggleFullScreen(nil) }
    if state == "title" {
      if edge(35) {
        save.easy.toggle()
        showTitle()
      }
      if edge(45) {
        state = "confirm"
        panel("Let the old flame go?", "This replaces your saved journey.")
        at(
          label("N  ·  Start anew          ESC  ·  Keep your journey", 18, gold), 640, 423, overlay)
      }
      if edge(36) { start() }
      return
    }
    if state == "confirm" {
      if edge(53) { showTitle() }
      if edge(45) {
        let easy = save.easy
        save = SaveData()
        save.easy = easy
        bloodValue = 0
        persist()
        buildRoom()
        buildHUD()
        start()
      }
      return
    }
    if state == "pause" {
      if edge(53) || edge(36) {
        state = previousState
        overlay.removeAllChildren()
      }
      if edge(35) {
        save.easy.toggle()
        persist()
        state = previousState
        showPause()
      }
      return
    }
    if state == "shrine" {
      if edge(53) || edge(14) {
        state = "play"
        overlay.removeAllChildren()
      }
      var cost = 0
      var choice = 0
      if edge(18) {
        cost = 70 + save.vitality * 65
        choice = 1
      }
      if edge(19) {
        cost = 85 + save.blade * 80
        choice = 2
      }
      if edge(20) && save.flask < 3 {
        cost = 150 + save.flask * 150
        choice = 3
      }
      if choice > 0 {
        if save.embers >= cost {
          save.embers -= cost
          if choice == 1 { save.vitality += 1 }
          if choice == 2 { save.blade += 1 }
          if choice == 3 { save.flask += 1 }
          player.maxHP = maxHP
          player.hp = maxHP
          flasks = maxFlasks
          audio.play("heal")
          persist()
          showShrine()
        } else {
          audio.play("roll")
        }
      }
      return
    }
    if state == "boon" {
      var choice = -1
      if edge(18) { choice = 0 }
      if edge(19) { choice = 1 }
      if edge(20) { choice = 2 }
      if choice >= 0 {
        save.boons.append(choice)
        persist()
        state = "play"
        overlay.removeAllChildren()
        notify("The northern seal is open. E at the arch to continue.", 6)
        audio.play("heal")
      }
      return
    }
    if state == "victory" {
      if edge(45) {
        state = "confirm"
        panel("Light another ember?", "This replaces your completed journey.")
        at(label("N  ·  Begin anew          ESC  ·  Return", 18, gold), 640, 425, overlay)
      }
      if edge(53) {
        state = "play"
        overlay.removeAllChildren()
      }
      return
    }
    if state == "dead" {
      if deathTime > 1.5 && (edge(36) || edge(14)) { respawn() }
      return
    }
    if edge(53) {
      showPause()
      return
    }
    if edge(14) {
      if dist(player.pos, shrine) < 95 && boss == nil
        && enemies.allSatisfy({ $0.dead || dist($0.pos, player.pos) > 180 })
      {
        rest()
        return
      }
      if dist(player.pos, gate) < 95 {
        if roomCleared {
          if save.chapter == 4 {
            showVictory()
          } else {
            save.chapter += 1
            save.cleared = false
            bloodValue = 0
            persist()
            buildRoom()
            buildHUD()
            showBanner(region.name, region.subtitle)
            notify("The ember travels with you. The next silence awaits.", 4)
          }
        } else if sentriesDead && boss == nil {
          beginBoss()
        }
      }
    }
    if player.action <= 0 && player.stun <= 0 {
      if edge(49) {
        dodge()
      } else if edge(37) {
        parry()
      } else if edge(15) {
        heal()
      } else if edge(40) {
        attack(true)
      } else if down(38) || mouseHeld {
        attack(false)
      }
    } else if edge(49) && player.actionType != "roll" && player.actionType != "heal"
      && player.action < 0.16
    {
      player.action = 0
      dodge()
    }
  }
  func movement() -> CGPoint {
    var p = CGPoint.zero
    if down(0) || down(123) { p.x -= 1 }
    if down(2) || down(124) { p.x += 1 }
    if down(13) || down(126) { p.y += 1 }
    if down(1) || down(125) { p.y -= 1 }
    return length(p) > 0 ? unit(p) : .zero
  }
  func aim() -> CGPoint {
    if mouseAim && dist(mouse, player.pos) > 10 { return unit(mouse - player.pos) }
    if let e = enemies.filter({ !$0.dead && dist($0.pos, player.pos) < 250 }).min(by: {
      dist($0.pos, player.pos) < dist($1.pos, player.pos)
    }) {
      return unit(e.pos - player.pos)
    }
    let m = movement()
    return length(m) > 0 ? m : player.facing
  }
  func spend(_ n: CGFloat) -> Bool {
    if player.stamina < n {
      notify("Catch your breath — stamina recovers when you stop attacking.", 1.2)
      return false
    }
    player.stamina -= n
    staminaDelay = 0.65
    return true
  }
  func dodge() {
    let cost = max(10, 25 - CGFloat(boonCount(1)) * 5)
    guard spend(cost) else { return }
    let m = movement()
    player.roll = length(m) > 0 ? m : player.facing
    player.facing = player.roll
    player.action = 0.34
    player.actionLength = 0.34
    player.actionType = "roll"
    player.invuln = 0.32
    audio.play("roll")
    particles(player.pos, hex(0xa9b5be), 8)
  }
  func parry() {
    guard spend(16) else { return }
    player.facing = aim()
    player.action = 0.44
    player.actionLength = 0.44
    player.actionType = "parry"
    player.attackDone = false
    audio.play("swing")
    let n = circle(31, .clear, gold, 3)
    n.position = player.pos
    effects.addChild(n)
    n.run(
      .sequence([
        .group([.scale(to: 1.3, duration: 0.24), .fadeOut(withDuration: 0.24)]),
        .removeFromParent(),
      ]))
  }
  func heal() {
    guard flasks > 0 && player.hp < maxHP else { return }
    flasks -= 1
    player.action = 0.86
    player.actionLength = 0.86
    player.actionType = "heal"
    player.attackDone = false
    notify("Mending…", 0.8)
    audio.play("heal")
  }
  func attack(_ heavy: Bool) {
    guard spend(heavy ? 31 : 16) else { return }
    player.facing = aim()
    player.action = heavy ? 0.65 : 0.32
    player.actionLength = player.action
    player.actionType = heavy ? "heavy" : "light"
    player.attackDone = false
    player.combo = (player.combo + 1) % 3
    audio.play("swing")
  }
  func strike(_ heavy: Bool) {
    let range: CGFloat = heavy ? 112 : 94
    let base = angle(player.facing)
    let arc: CGFloat = heavy ? 1.4 : 1.22
    let p = CGMutablePath()
    p.addArc(
      center: .zero, radius: range - 9, startAngle: base - arc, endAngle: base + arc,
      clockwise: false)
    let s = shape(p, .clear, heavy ? gold : ivory, heavy ? 8 : 4)
    s.position = player.pos
    s.zPosition = 30
    effects.addChild(s)
    s.run(
      .sequence([
        .group([.fadeOut(withDuration: 0.19), .scale(to: 1.12, duration: 0.19)]),
        .removeFromParent(),
      ]))
    for e in enemies where !e.dead {
      let diff = e.pos - player.pos
      let d = length(diff)
      if d < range + e.radius && (d < 45 || cos(angle(diff) - base) > cos(arc)) {
        var hit = damage * (heavy ? 1.85 : 1)
        if player.combo == 0 && !heavy { hit *= 1.22 }
        if e.stagger > 0 { hit *= 1.45 }
        if riposte > 0 {
          hit *= 1.65
          riposte = 0
        }
        hurtEnemy(e, hit, heavy ? 27 : 10)
        if boonCount(0) > 0 { player.hp = min(maxHP, player.hp + CGFloat(boonCount(0)) * 5) }
        if !e.isBoss { e.pos = e.pos + player.facing * (heavy ? 22 : 10) }
      }
    }
  }
  func hurtEnemy(_ e: Fighter, _ amount: CGFloat, _ posture: CGFloat) {
    guard !e.dead else { return }
    e.hp -= amount
    e.posture += posture
    e.hitFlash = 0.12
    e.body.alpha = 0.45
    particles(e.pos + CGPoint(x: 0, y: 15), accent, 10)
    floatText("\(Int(amount))", e.pos + CGPoint(x: 0, y: 40), ivory)
    audio.play("hit")
    cameraShake = 0.09
    shakeAmount = 3
    if e.hp <= 0 {
      kill(e)
      return
    }
    if e.posture >= 100 {
      stagger(e)
    } else if !e.isBoss && e.actionType != "windup" {
      e.stun = 0.25
    }
  }
  func stagger(_ e: Fighter) {
    e.posture = 0
    e.stagger = 2.8
    e.action = 0
    e.cooldown = 3
    e.tell?.removeFromParent()
    e.tell = nil
    e.actionType = ""
    particles(e.pos, gold, 25)
    floatText("BROKEN", e.pos + CGPoint(x: 0, y: 66), gold)
    audio.play("parry")
    if e.isBoss { notify("Resolve broken — strike now!", 2) }
  }
  func kill(_ e: Fighter) {
    e.dead = true
    e.tell?.removeFromParent()
    e.tell = nil
    particles(e.pos, accent, e.isBoss ? 85 : 22)
    e.node.run(
      .sequence([
        .group([.fadeOut(withDuration: 0.45), .scale(to: 0.8, duration: 0.45)]),
        .removeFromParent(),
      ]))
    let reward = e.isBoss ? 210 + save.chapter * 95 : 35 + save.chapter * 7
    save.embers += reward
    floatText("+\(reward)", e.pos + CGPoint(x: 0, y: 25), gold)
    if e.isBoss {
      boss = nil
      bossHUD.isHidden = true
      roomCleared = true
      save.cleared = true
      player.hp = maxHP
      flasks = maxFlasks
      for h in hazards { h.node.removeFromParent() }
      hazards = []
      for p in projectiles { p.node.removeFromParent() }
      projectiles = []
      for other in enemies where !other.dead {
        other.dead = true
        other.node.removeFromParent()
      }
      audio.play("win")
      persist()
      showBanner("SILENCE BROKEN", region.boss)
      transition = 3.3
      cameraShake = 0.5
      shakeAmount = 7
    } else if enemies.allSatisfy({ $0.dead }) {
      sentriesDead = true
      notify("The sentries are still. Approach the northern seal and press E.", 5)
    }
  }
  func hurtPlayer(
    _ amount: CGFloat, _ from: CGPoint, _ parryable: Bool = false, _ owner: Fighter? = nil
  ) {
    guard state == "play", player.invuln <= 0, player.hp > 0 else { return }
    if player.actionType == "parry" && player.action > 0.19 && parryable {
      player.stamina = min(100, player.stamina + 30)
      player.invuln = 0.35
      riposte = 3
      audio.play("parry")
      particles(player.pos, gold, 36)
      floatText("PARRY", player.pos + CGPoint(x: 0, y: 50), gold)
      if let e = owner {
        e.posture += 52
        if e.posture >= 100 || !e.isBoss {
          stagger(e)
        } else {
          e.stun = 0.6
          e.cooldown = max(e.cooldown, 0.9)
        }
      }
      player.hp = min(maxHP, player.hp + CGFloat(boonCount(2)) * 15)
      cameraShake = 0.18
      shakeAmount = 6
      return
    }
    let d = amount * (save.easy ? 0.62 : 1)
    player.hp -= d
    player.invuln = 0.72
    player.stun = 0.15
    player.action = 0
    player.actionType = ""
    player.pos = bounded(player.pos + unit(player.pos - from) * 18)
    particles(player.pos, red, 18)
    floatText("−\(Int(d))", player.pos + CGPoint(x: 0, y: 40), red)
    audio.play("hit")
    cameraShake = 0.18
    shakeAmount = 6
    if player.hp <= 0 { die() }
  }
  func die() {
    state = "dead"
    deathTime = 0
    save.deaths += 1
    bloodValue = save.embers
    save.embers = 0
    bloodPoint = player.pos
    persist()
    audio.play("death")
    player.node.alpha = 0.3
    overlay.removeAllChildren()
    at(rect(1280, 800, hex(0x090b12, 0.7)), 640, 400, overlay)
    at(label("THE EMBER FADES", 53, hex(0xb5605e), "Baskerville"), 640, 450, overlay)
    at(label("\(bloodValue) embers wait where you fell.", 17, ivory), 640, 389, overlay)
    at(label("RETURN   ·   Rise again", 19, gold), 640, 310, overlay)
  }
  func respawn() {
    state = "play"
    overlay.removeAllChildren()
    buildRoom()
    buildHUD()
    notify("Return to your fallen ember to reclaim what was lost.", 5)
  }
  func bounded(_ p: CGPoint) -> CGPoint {
    CGPoint(x: clamp(p.x, 202, 1078), y: clamp(p.y, 145, 626))
  }
  func particles(_ p: CGPoint, _ color: NSColor, _ count: Int) {
    for _ in 0..<count {
      let s = circle(CGFloat.random(in: 1...3.4), color)
      s.position = p
      s.zPosition = 40
      effects.addChild(s)
      let a = CGFloat.random(in: 0...pi * 2)
      let d = CGFloat.random(in: 18...95)
      s.run(
        .sequence([
          .group([
            .moveBy(x: cos(a) * d, y: sin(a) * d, duration: 0.25 + Double(d) / 200),
            .fadeOut(withDuration: 0.55), .scale(to: 0.1, duration: 0.6),
          ]), .removeFromParent(),
        ]))
    }
  }
  func floatText(_ t: String, _ p: CGPoint, _ c: NSColor) {
    let l = label(t, 16, c, "AvenirNext-DemiBold")
    l.position = p
    l.zPosition = 100
    effects.addChild(l)
    l.run(
      .sequence([
        .group([
          .moveBy(x: 0, y: 40, duration: 0.7),
          .sequence([.wait(forDuration: 0.25), .fadeOut(withDuration: 0.45)]),
        ]), .removeFromParent(),
      ]))
  }
  func tellMelee(_ e: Fighter, _ delay: CGFloat, _ wide: Bool = false) {
    e.actionType = wide ? "sweep" : "windup"
    e.action = delay
    e.actionLength = delay
    e.aim = angle(player.pos - e.pos)
    e.facing = direction(e.aim)
    let reach: CGFloat = e.isBoss ? (wide ? 158 : 135) : 88
    let arc: CGFloat = wide ? 2.4 : 1.0
    let path = CGMutablePath()
    path.move(to: .zero)
    path.addArc(center: .zero, radius: reach, startAngle: -arc, endAngle: arc, clockwise: false)
    path.closeSubpath()
    let n = shape(path, red.withAlphaComponent(0.14), hex(0xee8273, 0.65), 1.5)
    n.position = e.pos
    n.zRotation = e.aim
    n.zPosition = -1
    effects.addChild(n)
    e.tell = n
  }
  func circleHazard(_ p: CGPoint, _ r: CGFloat, _ delay: CGFloat, _ damage: CGFloat) {
    let n = SKNode()
    n.addChild(circle(r, red.withAlphaComponent(0.09), hex(0xf19977, 0.65), 2))
    let inner = circle(r * 0.12, .clear, gold.withAlphaComponent(0.8), 1)
    n.addChild(inner)
    inner.run(.scale(to: 8.3, duration: Double(delay)))
    n.position = p
    effects.addChild(n)
    hazards.append(
      Hazard(
        node: n, pos: p, delay: delay, duration: 0.32, radius: r, damage: damage,
        type: "circle"))
  }
  func ring(_ p: CGPoint, _ delay: CGFloat, _ damage: CGFloat) {
    let n = circle(20, .clear, accent.withAlphaComponent(0.7), 5)
    n.position = p
    effects.addChild(n)
    hazards.append(
      Hazard(
        node: n, pos: p, delay: delay, duration: 1.7, radius: 20, damage: damage,
        type: "ring"))
  }
  func charge(_ e: Fighter, _ delay: CGFloat) {
    e.actionType = "charge"
    e.action = delay
    e.actionLength = delay
    e.aim = angle(player.pos - e.pos)
    e.target = bounded(e.pos + direction(e.aim) * 560)
    let p = CGMutablePath()
    p.move(to: e.pos)
    p.addLine(to: e.target)
    let line = shape(p, .clear, red.withAlphaComponent(0.22), 70)
    effects.addChild(line)
    let middle = shape(p, .clear, gold.withAlphaComponent(0.7), 2)
    line.addChild(middle)
    e.tell = line
    e.facing = direction(e.aim)
  }
  func volley(_ e: Fighter, _ count: Int, _ full: Bool = false, _ speed: CGFloat = 190) {
    let a = angle(player.pos - e.pos)
    for i in 0..<count {
      let theta =
        full
        ? CGFloat(i) * 2 * pi / CGFloat(count) + time * 0.3
        : a + (CGFloat(i) - CGFloat(count - 1) / 2) * 0.23
      let n = SKNode()
      n.addChild(glow(17, accent))
      n.addChild(circle(6, accent))
      n.position = e.pos
      effects.addChild(n)
      projectiles.append(
        Projectile(
          node: n, velocity: direction(theta) * speed, life: 5,
          damage: 19 + CGFloat(save.chapter) * 2, radius: 8))
    }
    audio.play("swing")
  }
  func decide(_ e: Fighter) {
    if !e.isBoss {
      if dist(e.pos, player.pos) < 94 { tellMelee(e, 0.73) }
      return
    }
    e.pattern += 1
    let p = e.pattern
    let phase = e.phase
    switch e.kind {
    case 0:
      if p % 4 == 0 {
        e.actionType = "slam"
        e.action = 0.95
        e.actionLength = 0.95
        circleHazard(e.pos, 125, 0.95, 30)
        ring(e.pos, 1.05, 24)
        notify("The bell tolls — dodge through the expanding ring.", 2)
      } else {
        tellMelee(e, phase == 2 ? 0.65 : 0.82, p % 3 == 0)
      }
    case 1:
      if p % 4 == 0 {
        e.actionType = "cast"
        e.action = 0.95
        e.actionLength = 0.95
        for i in 0..<(phase == 2 ? 5 : 3) {
          let offset = direction(CGFloat(i) * 2 * pi / 3) * CGFloat(i == 0 ? 0 : 90)
          circleHazard(bounded(player.pos + offset), 57, 0.85 + CGFloat(i) * 0.17, 26)
        }
      } else if p % 3 == 0 {
        e.actionType = "volley"
        e.action = 0.8
        e.actionLength = 0.8
        let flash = glow(60, accent)
        e.node.addChild(flash)
        flash.run(.sequence([.fadeOut(withDuration: 0.8), .removeFromParent()]))
      } else {
        tellMelee(e, 0.7, true)
      }
    case 2:
      if p % 3 != 0 {
        charge(e, phase == 2 ? 0.68 : 0.9)
      } else {
        e.actionType = "slam"
        e.action = 0.85
        e.actionLength = 0.85
        circleHazard(e.pos, 120, 0.85, 29)
        ring(e.pos, 0.95, 24)
        if phase == 2 { ring(e.pos, 1.4, 24) }
      }
    case 3:
      if p % 3 == 0 {
        e.actionType = "cast"
        e.action = 1
        e.actionLength = 1
        for i in 0..<(phase == 2 ? 6 : 4) {
          circleHazard(
            bounded(
              player.pos + CGPoint(x: CGFloat(i % 3 - 1) * 105, y: CGFloat(i / 3) * 115 - 50)), 48,
            0.8 + CGFloat(i) * 0.14, 25)
        }
      } else if p % 3 == 1 {
        e.actionType = "nova"
        e.action = 0.8
        e.actionLength = 0.8
        let n = circle(65, .clear, accent, 2)
        e.node.addChild(n)
        n.run(.sequence([.fadeOut(withDuration: 0.8), .removeFromParent()]))
      } else {
        tellMelee(e, 0.72, true)
      }
    default:
      switch p % 5 {
      case 0: charge(e, 0.65)
      case 1: tellMelee(e, 0.62, true)
      case 2:
        e.actionType = "nova"
        e.action = 0.85
        e.actionLength = 0.85
        ring(e.pos, 0.9, 28)
      case 3:
        e.actionType = "cast"
        e.action = 0.9
        e.actionLength = 0.9
        for i in 0..<(phase == 2 ? 5 : 3) {
          circleHazard(
            bounded(player.pos + direction(CGFloat(i) * 2.4) * CGFloat(i * 43)), 52,
            0.75 + CGFloat(i) * 0.2, 29)
        }
      default: tellMelee(e, 0.55)
      }
    }
  }
}
