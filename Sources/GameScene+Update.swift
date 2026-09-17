import AppKit
import SpriteKit

extension GameScene {
  func updateEnemy(_ e: Fighter, _ dt: CGFloat) {
    guard !e.dead else { return }
    e.invuln = max(0, e.invuln - dt)
    e.stun = max(0, e.stun - dt)
    e.stagger = max(0, e.stagger - dt)
    e.cooldown = max(0, e.cooldown - dt)
    e.hitFlash = max(0, e.hitFlash - dt)
    if e.hitFlash <= 0 { e.body.alpha = 1 }
    if e.action <= 0 { e.posture = max(0, e.posture - dt * 4) }
    if let bar = e.healthBar { bar.xScale = max(0, e.hp / e.maxHP) }
    if e.isBoss && e.hp < e.maxHP * 0.5 && e.phase == 1 {
      e.phase = 2
      particles(e.pos, accent, 50)
      notify("\(region.boss)  ·  THE VOW UNRAVELS", 3)
      audio.play("boss")
      e.cooldown = 0.4
    }
    if e.stagger > 0 {
      e.body.zRotation = sin(time * 13) * 0.08
      e.weapon.zRotation = -1
      return
    }
    e.body.zRotation = 0
    if e.stun > 0 { return }
    if bossIntro > 0 && e.isBoss { return }
    if e.action > 0 {
      e.action -= dt
      let progress = 1 - e.action / e.actionLength
      if e.actionType == "dash" {
        let step = direction(e.aim) * 760 * dt
        e.pos = bounded(e.pos + step)
        if dist(e.pos, player.pos) < e.radius + 24 {
          hurtPlayer(28 + CGFloat(save.chapter) * 2, e.pos, true, e)
        }
        if Int(time * 35) % 2 == 0 { particles(e.pos, accent, 1) }
      } else {
        e.tell?.alpha = 0.45 + progress * 0.55
        e.weapon.zRotation = e.aim - 1.5 + progress * 0.6
        e.body.position.y = sin(progress * pi) * 4
      }
      if e.action <= 0 {
        e.tell?.removeFromParent()
        e.tell = nil
        e.body.position.y = 0
        switch e.actionType {
        case "windup", "sweep":
          let wide = e.actionType == "sweep"
          let reach: CGFloat = e.isBoss ? (wide ? 158 : 135) : 88
          let arc: CGFloat = wide ? 2.4 : 1.0
          let d = player.pos - e.pos
          if length(d) < reach + 13 && cos(angle(d) - e.aim) > cos(arc) {
            hurtPlayer(
              e.isBoss ? 26 + CGFloat(e.kind) * 2 : 17 + CGFloat(e.kind) * 2, e.pos, true, e)
          }
          let p = CGMutablePath()
          p.addArc(
            center: e.pos, radius: reach - 10, startAngle: e.aim - arc, endAngle: e.aim + arc,
            clockwise: false)
          let slash = shape(p, .clear, accent, 6)
          effects.addChild(slash)
          slash.run(.sequence([.fadeOut(withDuration: 0.2), .removeFromParent()]))
          audio.play("swing")
          e.cooldown = e.isBoss ? (e.phase == 2 ? 0.64 : 0.95) : 1.1
        case "charge":
          e.actionType = "dash"
          e.action = dist(e.pos, e.target) / 760
          e.actionLength = e.action
          audio.play("swing")
          return
        case "dash":
          e.cooldown = 1.15
          particles(e.pos, accent, 18)
        case "volley":
          volley(e, e.phase == 2 ? 7 : 5)
          e.cooldown = 0.95
        case "nova":
          volley(e, e.phase == 2 ? 16 : 12, true, e.kind == 4 ? 180 : 155)
          if e.phase == 2 { volley(e, 3, false, 220) }
          e.cooldown = 1.25
        case "slam":
          particles(e.pos, accent, 30)
          audio.play("boss")
          cameraShake = 0.3
          shakeAmount = 5
          e.cooldown = 1.3
        default: e.cooldown = 1.05
        }
        e.actionType = ""
      }
      return
    }
    let diff = player.pos - e.pos
    let d = length(diff)
    if !e.isBoss && d > 340 { return }
    e.facing = unit(diff)
    e.weapon.zRotation = angle(e.facing)
    let preferred: CGFloat = e.isBoss ? (e.kind == 3 ? 215 : e.kind == 1 ? 135 : 100) : 65
    if d > preferred {
      let velocity: CGFloat =
        e.isBoss ? (e.kind == 2 ? 100 : e.kind == 3 ? 85 : 125) + (e.phase == 2 ? 20 : 0) : 104
      var step = unit(diff) * velocity * dt
      for other in enemies where other !== e && !other.dead {
        if dist(e.pos, other.pos) < e.radius + other.radius + 8 {
          step = step + unit(e.pos - other.pos) * 50 * dt
        }
      }
      e.pos = bounded(e.pos + step)
      e.walk += dt * 8
      e.body.position.y = sin(e.walk) * 2
    }
    if e.cooldown <= 0 {
      if e.isBoss {
        if d < 190 || e.kind > 0 || e.pattern % 4 == 3 { decide(e) }
      } else {
        decide(e)
      }
    }
  }
  func updateHazards(_ dt: CGFloat) {
    for i in hazards.indices {
      hazards[i].age += dt
      let h = hazards[i]
      if h.age < h.delay { continue }
      let t = h.age - h.delay
      if h.type == "circle" {
        if !h.hit {
          hazards[i].hit = true
          h.node.removeAllChildren()
          h.node.addChild(circle(h.radius, accent.withAlphaComponent(0.24), accent, 3))
          particles(h.pos, accent, 12)
          if dist(player.pos, h.pos) < h.radius + 10 { hurtPlayer(h.damage, h.pos) }
        }
        h.node.alpha = max(0, 1 - t / h.duration)
      } else {
        let radius = 20 + t * 270
        if let n = h.node as? SKShapeNode {
          n.path = CGPath(
            ellipseIn: CGRect(x: -radius, y: -radius, width: radius * 2, height: radius * 2),
            transform: nil)
          n.alpha = max(0, 1 - t / h.duration)
        }
        if abs(dist(player.pos, h.pos) - radius) < 17 { hurtPlayer(h.damage, h.pos) }
      }
    }
    hazards.removeAll { h in
      if h.age > h.delay + h.duration {
        h.node.removeFromParent()
        return true
      }
      return false
    }
  }
  func updateProjectiles(_ dt: CGFloat) {
    for i in projectiles.indices {
      guard projectiles.indices.contains(i) else { break }
      projectiles[i].life -= dt
      projectiles[i].node.position = projectiles[i].node.position + projectiles[i].velocity * dt
      let p = projectiles[i]
      if p.reflected {
        if let e = enemies.first(where: {
          !$0.dead && dist($0.pos, p.node.position) < $0.radius + 10
        }) {
          projectiles[i].life = 0
          hurtEnemy(e, damage * 1.5, 22)
        }
      } else if dist(p.node.position, player.pos) < p.radius + 20 {
        if player.actionType == "parry" && player.action > 0.19 {
          projectiles[i].reflected = true
          projectiles[i].velocity =
            unit((boss?.pos ?? player.pos + player.facing * 200) - p.node.position) * 420
          player.stamina = min(100, player.stamina + 16)
          audio.play("parry")
          particles(p.node.position, gold, 12)
          riposte = 3
        } else if player.invuln <= 0 {
          hurtPlayer(p.damage, p.node.position)
          projectiles[i].life = 0
        }
      }
    }
    projectiles.removeAll { p in
      if p.life <= 0 || p.node.position.x < 110 || p.node.position.x > 1170
        || p.node.position.y < 90 || p.node.position.y > 690
      {
        p.node.removeFromParent()
        return true
      }
      return false
    }
  }
  override func update(_ currentTime: TimeInterval) {
    let dt: CGFloat = lastTime == 0 ? 1 / 60 : min(0.033, CGFloat(currentTime - lastTime))
    lastTime = currentTime
    input()
    pressed.removeAll()
    if state == "dead" {
      deathTime += dt
      return
    }
    guard state == "play" else { return }
    time += dt
    messageTime -= dt
    notification.alpha = min(1, max(0, messageTime * 2))
    bossIntro = max(0, bossIntro - dt)
    riposte = max(0, riposte - dt)
    if transition > 0 {
      transition -= dt
      if transition <= 0 {
        if save.chapter == 4 { showVictory() } else { showBoons() }
        return
      }
    }
    if cameraShake > 0 {
      cameraShake -= dt
      world.position = CGPoint(
        x: CGFloat.random(in: -shakeAmount...shakeAmount),
        y: CGFloat.random(in: -shakeAmount...shakeAmount))
    } else {
      world.position = .zero
    }
    player.invuln = max(0, player.invuln - dt)
    player.stun = max(0, player.stun - dt)
    staminaDelay = max(0, staminaDelay - dt)
    if staminaDelay <= 0 && player.actionType != "roll" {
      player.stamina = min(100, player.stamina + dt * 37)
    }
    let m = movement()
    var moving = false
    if player.action > 0 {
      player.action -= dt
      let progress = 1 - player.action / player.actionLength
      switch player.actionType {
      case "roll":
        player.pos = bounded(player.pos + player.roll * 470 * dt)
        player.body.zRotation = sin(progress * pi * 2) * 0.4
        player.body.yScale = 0.65
        moving = true
      case "light", "heavy":
        let heavy = player.actionType == "heavy"
        let strikeTime: CGFloat = heavy ? 0.28 : 0.10
        if !player.attackDone && progress * player.actionLength >= strikeTime {
          player.attackDone = true
          strike(heavy)
        }
        player.weapon.zRotation = angle(player.facing) - 1.5 + progress * 3.3
        player.pos = bounded(player.pos + m * moveSpeed * 0.30 * dt)
      case "heal":
        if Int(time * 25) % 3 == 0 {
          particles(player.pos + CGPoint(x: 0, y: 20), hex(0x91d2aa), 1)
        }
        if player.action <= 0 {
          player.hp = min(maxHP, player.hp + maxHP * 0.55)
          particles(player.pos, hex(0x98dcad), 25)
          floatText("MENDED", player.pos + CGPoint(x: 0, y: 50), hex(0x98dcad))
        }
      default:
        player.weapon.zRotation = angle(player.facing) + 1.15
        player.pos = bounded(player.pos + m * moveSpeed * 0.4 * dt)
      }
      if player.action <= 0 {
        player.actionType = ""
        player.body.yScale = 1
        player.body.zRotation = 0
      }
    } else if player.stun <= 0 {
      player.pos = bounded(player.pos + m * moveSpeed * dt)
      moving = length(m) > 0
      if moving { player.facing = mouseAim ? aim() : m }
      player.weapon.zRotation = angle(player.facing)
    }
    if moving { player.walk += dt * 13 }
    player.body.position.y = moving ? sin(player.walk) * 2 : sin(time * 2) * 0.6
    player.node.alpha = player.invuln > 0 ? (sin(time * 45) > 0 ? 0.48 : 0.85) : 1
    player.node.zPosition = 700 - player.pos.y
    for e in enemies {
      updateEnemy(e, dt)
      e.node.zPosition = 700 - e.pos.y
    }
    updateHazards(dt)
    updateProjectiles(dt)
    if bloodValue > 0 && dist(player.pos, bloodPoint) < 32 {
      save.embers += bloodValue
      notify("\(bloodValue) embers reclaimed.", 3)
      bloodValue = 0
      blood?.removeFromParent()
      blood = nil
      particles(player.pos, hex(0x94dcd1), 20)
      audio.play("heal")
      persist()
    }
    hpFill.xScale = max(0, player.hp / maxHP)
    hpFill.position.x = 66 + 128 * hpFill.xScale
    stFill.xScale = player.stamina / 100
    stFill.position.x = 66 + 128 * stFill.xScale
    flaskLabel.text = "✦  \(flasks) / \(maxFlasks)  flasks"
    emberLabel.text = "✧  \(save.embers)  embers"
    if let b = boss {
      bossBar.xScale = max(0, b.hp / b.maxHP)
      bossBar.position.x = 283 + 357 * bossBar.xScale
      postureBar.xScale = b.posture / 100
      postureBar.position.x = 283 + 357 * postureBar.xScale
      bossTitle.text = region.boss + (b.phase == 2 ? "  ·  UNRAVELED" : "")
    }
    interactText.text = ""
    if dist(player.pos, shrine) < 95 && boss == nil {
      interactText.text = "E  ·  Rest / strengthen the ember"
    } else if dist(player.pos, gate) < 95 && boss == nil {
      interactText.text =
        roomCleared
        ? "E  ·  \(save.chapter==4 ? "Witness the dawn":"Pass beyond the seal")"
        : sentriesDead ? "E  ·  Ring the seal" : "The seal awaits the silence of its sentries"
    }
    hint.text =
      boss != nil
      ? "Pale arcs can be parried. Red ground marks must be dodged. Heavy strikes break resolve."
      : "\(roomCleared ? "Guardian defeated. Spend your embers at the fire, then continue north." : "Defeat the lost sentries, then approach the northern seal.")"
  }
}
