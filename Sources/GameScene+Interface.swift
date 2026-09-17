import AppKit
import SpriteKit

extension GameScene {
  func buildHUD() {
    hud.removeAllChildren()
    at(rect(1280, 96, hex(0x080d14, 0.93)), 640, 752, hud)
    at(rect(1280, 62, hex(0x080d14, 0.93)), 640, 31, hud)
    at(rect(1160, 1, hex(0x9a855d, 0.25)), 640, 704, hud)
    at(label("THE LAST EMBER", 16, gold, "AvenirNext-DemiBold"), 164, 774, hud)
    at(rect(262, 17, hex(0x2c222b), 3), 194, 745, hud)
    hpFill = rect(256, 11, red, 2)
    hpFill.position = CGPoint(x: 194, y: 745)
    hud.addChild(hpFill)
    at(rect(262, 9, hex(0x182624), 2), 194, 726, hud)
    stFill = rect(256, 5, hex(0x91baa0), 2)
    stFill.position = CGPoint(x: 194, y: 726)
    hud.addChild(stFill)
    flaskLabel = label("", 16, ivory)
    at(flaskLabel, 407, 747, hud)
    emberLabel = label("", 16, gold)
    at(emberLabel, 407, 725, hud)
    regionLabel = label(region.name, 15, ivory, "AvenirNext-DemiBold")
    at(regionLabel, 960, 767, hud)
    at(label(region.subtitle, 12, hex(0x9ba5ae)), 960, 743, hud)
    at(
      label(
        "WASD move    J / click strike    K heavy    SPACE dodge    L parry    R heal    E interact",
        13, hex(0xa6adb1)), 574, 29, hud)
    at(label("ESC pause", 12, gold), 1165, 29, hud)
    interactText = label("", 15, gold, "AvenirNext-DemiBold")
    at(interactText, 640, 89, hud)
    bossHUD = SKNode()
    at(rect(720, 11, hex(0x30212a), 3), 640, 675, bossHUD)
    bossBar = rect(714, 6, red, 2)
    at(bossBar, 640, 675, bossHUD)
    postureBar = rect(714, 2, gold)
    at(postureBar, 640, 665, bossHUD)
    bossTitle = label("", 13, ivory, "AvenirNext-DemiBold")
    at(bossTitle, 640, 692, bossHUD)
    hud.addChild(bossHUD)
    bossHUD.isHidden = true
    notification = SKNode()
    at(notification, 640, 126, hud)
    hint = label("", 13, hex(0xa8b0b5))
    at(hint, 640, 61, hud)
  }
  func panel(_ title: String, _ sub: String) {
    overlay.removeAllChildren()
    at(rect(1280, 800, hex(0x070c13, 0.88)), 640, 400, overlay)
    at(rect(780, 470, hex(0x111924, 0.96), 12), 640, 414, overlay)
    at(rect(670, 1, gold.withAlphaComponent(0.3)), 640, 533, overlay)
    at(label(title, 37, ivory, "Baskerville"), 640, 585, overlay)
    at(label(sub, 15, hex(0xa6aeb6)), 640, 548, overlay)
  }
  func showTitle() {
    state = "title"
    hud.isHidden = true
    overlay.removeAllChildren()
    at(rect(1280, 800, hex(0x070b13, 0.73)), 640, 400, overlay)
    at(label("A SOULSLIKE IN FIVE REQUIEMS", 13, gold, "AvenirNext-DemiBold"), 640, 665, overlay)
    at(label("THE LAST", 43, ivory, "Baskerville"), 640, 595, overlay)
    let t = label("E M B E R", 96, ivory, "Baskerville")
    at(t, 640, 512, overlay)
    at(rect(290, 1, gold.withAlphaComponent(0.5)), 640, 445, overlay)
    at(
      label("The world has gone quiet. Carry its last fire.", 18, hex(0xb8bab8), "Baskerville"),
      640, 406, overlay)
    at(
      label(
        save.chapter > 0 || save.embers > 0 || save.deaths > 0
          ? "RETURN  ·  Continue your vigil" : "RETURN  ·  Begin your vigil", 21, gold,
        "AvenirNext-DemiBold"), 640, 332, overlay)
    at(
      label("WASD move   ·   J strike   ·   K heavy   ·   SPACE dodge", 15, ivory), 640, 265,
      overlay)
    at(label("L parry   ·   R mend   ·   E commune   ·   ESC pause", 15, ivory), 640, 236, overlay)
    at(
      label("Dodge through attacks. A perfect parry breaks their resolve.", 14, hex(0x9ca9b5)), 640,
      193, overlay)
    at(
      label(
        "P  ·  \(save.easy ? "PILGRIM — gentler damage" : "VIGIL — the intended challenge")", 13,
        accent), 640, 126, overlay)
    at(
      label("N  ·  New journey     M  ·  Sound     F  ·  Full screen", 12, hex(0x798b99)), 640, 90,
      overlay)
  }
  func start() {
    state = "play"
    overlay.removeAllChildren()
    hud.isHidden = false
    showBanner(region.name, region.subtitle)
    notify("Clear the lost sentries. Then ring the seal at the northern arch.", 5)
  }
  func notify(_ text: String, _ duration: CGFloat = 3) {
    notification.removeAllChildren()
    let l = label(text, 15, ivory)
    notification.addChild(l)
    messageTime = duration
  }
  func showBanner(_ title: String, _ sub: String) {
    banner.removeFromParent()
    banner = SKNode()
    banner.zPosition = 800
    at(rect(1280, 130, hex(0x080c12, 0.8)), 640, 425, banner)
    at(label(title, 37, ivory, "Baskerville"), 640, 441, banner)
    at(label(sub, 14, gold), 640, 402, banner)
    hud.addChild(banner)
    banner.run(
      .sequence([.wait(forDuration: 2.6), .fadeOut(withDuration: 0.6), .removeFromParent()]))
  }
  func showShrine() {
    state = "shrine"
    panel(
      "The ember remembers",
      "Rest restores your blood and all mending flasks.  ·  \(save.embers) embers held")
    let a = 70 + save.vitality * 65
    let b = 85 + save.blade * 80
    let c = 150 + save.flask * 150
    at(
      label("1   Temper flesh    ·    +25 maximum health    ·    \(a) embers", 18, ivory), 640, 480,
      overlay)
    at(
      label("2   Hone the blade    ·    +6 strike damage    ·    \(b) embers", 18, ivory), 640, 430,
      overlay)
    at(
      label(
        save.flask < 3
          ? "3   Kindle a flask    ·    +1 healing charge    ·    \(c) embers"
          : "3   Flasks fully kindled", 18, ivory), 640, 380, overlay)
    at(
      label(
        "Flesh \(save.vitality)     /     Blade \(save.blade)     /     Flasks \(maxFlasks)", 14,
        gold), 640, 320, overlay)
    at(label("E / ESC   ·   Leave the ember", 16, gold), 640, 258, overlay)
  }
  func rest() {
    player.hp = maxHP
    player.maxHP = maxHP
    player.stamina = 100
    flasks = maxFlasks
    audio.play("heal")
    persist()
    showShrine()
  }
  func showPause() {
    previousState = state
    state = "pause"
    panel("A breath between ashes", "The world waits for you.")
    at(label("ESC / RETURN   ·   Resume", 20, gold), 640, 470, overlay)
    at(
      label(
        "P   ·   \(save.easy ? "Pilgrim — reduced incoming damage" : "Vigil — standard challenge")",
        17, ivory), 640, 412, overlay)
    at(
      label("M   ·   Sound \(audio.enabled ? "on" : "off")     F   ·   Full screen", 17, ivory),
      640, 360, overlay)
    at(
      label("J strike · K heavy · L parry · R heal · E interact", 16, hex(0xa3adb7)), 640, 307,
      overlay)
    at(
      label("Progress is saved at every ember and every fallen guardian.", 13, hex(0x8b99a5)), 640,
      261, overlay)
  }
  func showBoons() {
    state = "boon"
    panel(
      "A flame made stronger", "Take one memory from the fallen. Its gift lasts for this journey.")
    at(
      label("1   HUNGER    ·    Recover 5 health with every melee hit", 18, ivory), 640, 471,
      overlay)
    at(label("2   MOMENTUM    ·    Dodging costs 5 less stamina", 18, ivory), 640, 411, overlay)
    at(
      label("3   RESOLVE    ·    Parries restore health and empower the next strike", 18, ivory),
      640, 351, overlay)
    at(label("Gifts can be taken again to deepen their strength.", 14, gold), 640, 277, overlay)
  }
  func showVictory() {
    state = "victory"
    save.won = true
    persist()
    panel("And so the dawn returns.", "Five silences broken. One ember carried home.")
    at(label("You did not save the old world.", 23, ivory, "Baskerville"), 640, 461, overlay)
    at(label("You gave the new one a morning.", 23, gold, "Baskerville"), 640, 424, overlay)
    at(
      label(
        "\(save.deaths) deaths  ·  \(save.easy ? "Pilgrim" : "Vigil")  ·  Blade +\(save.blade)  ·  Flesh +\(save.vitality)",
        15, hex(0xa6b1b8)), 640, 350, overlay)
    at(
      label("N  ·  Begin a new journey      ESC  ·  Remain in the dawn", 16, gold), 640, 275,
      overlay)
  }
  func beginBoss() {
    let b = Fighter(kind: save.chapter, boss: true)
    b.pos = CGPoint(x: 640, y: 535)
    b.hp = region.health
    b.maxHP = b.hp
    b.cooldown = 2.6
    enemies.append(b)
    actors.addChild(b.node)
    boss = b
    bossIntro = 2.5
    bossHUD.isHidden = false
    bossTitle.text = region.boss
    player.pos = CGPoint(x: 640, y: 340)
    player.action = 0
    audio.play("boss")
    showBanner(region.boss, region.epithet)
    notify(region.lore, 5)
    sentriesDead = true
    particles(b.pos, accent, 45)
    cameraShake = 0.4
    shakeAmount = 4
  }
}
