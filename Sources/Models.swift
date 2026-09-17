import AppKit
import Foundation
import SpriteKit

struct Region {
  let name: String
  let subtitle: String
  let boss: String
  let epithet: String
  let color: UInt32
  let floor: UInt32
  let health: CGFloat
  let lore: String
}
let regions = [
  Region(
    name: "THE HUSHED GATE", subtitle: "I  ·  A bell that never mourned", boss: "BELLWARDEN VOSS",
    epithet: "Keeper of the first silence", color: 0xddac69, floor: 0x20262b, health: 680,
    lore: "He rang the bells until there was no one left to answer."),
  Region(
    name: "THE THORN CHAPEL", subtitle: "II  ·  Where prayers took root", boss: "THE BRIAR BRIDE",
    epithet: "She who married the garden", color: 0x97bc91, floor: 0x192b2b, health: 800,
    lore: "She asked the earth to keep him. It kept everything."),
  Region(
    name: "THE DROWNED COURT", subtitle: "III  ·  Beneath a borrowed moon",
    boss: "SIR NERETH, THE SUNKEN", epithet: "Last knight of the tide", color: 0x77bfd1,
    floor: 0x1b2b38, health: 940, lore: "Still he guards a kingdom that the sea has forgotten."),
  Region(
    name: "THE ASHEN CHOIR", subtitle: "IV  ·  The song beneath the fire",
    boss: "MOTHER OF CINDERS", epithet: "A thousand voices, one flame", color: 0xec8f6d,
    floor: 0x302325, health: 1060, lore: "Every voice she stole still sings inside the ash."),
  Region(
    name: "THE PALE MERIDIAN", subtitle: "V  ·  The end of the long night", boss: "THE HOLLOW SUN",
    epithet: "The light that would not die", color: 0xe6cb87, floor: 0x2d2a32, health: 1300,
    lore: "The sun did not abandon us. We taught it to hunger."),
]

final class Fighter {
  let node = SKNode()
  let body = SKNode()
  let weapon = SKNode()
  let shadow = SKShapeNode(ellipseOf: CGSize(width: 42, height: 18))
  var hp: CGFloat = 100
  var maxHP: CGFloat = 100
  var stamina: CGFloat = 100
  var pos: CGPoint {
    get { node.position }
    set { node.position = newValue }
  }
  var facing = CGPoint(x: 0, y: 1)
  var radius: CGFloat = 18
  var invuln: CGFloat = 0
  var stun: CGFloat = 0
  var cooldown: CGFloat = 0
  var action: CGFloat = 0
  var actionLength: CGFloat = 0
  var attackDone = false
  var actionType = ""
  var roll = CGPoint.zero
  var isBoss = false
  var kind = 0
  var phase = 1
  var pattern = 0
  var posture: CGFloat = 0
  var stagger: CGFloat = 0
  var tell: SKNode?
  var target = CGPoint.zero
  var aim: CGFloat = 0
  var dead = false
  var walk: CGFloat = 0
  var hitFlash: CGFloat = 0
  var healthBar: SKShapeNode?
  var combo = 0
  init(kind: Int, boss: Bool = false, player: Bool = false) {
    self.kind = kind
    isBoss = boss
    node.addChild(shadow)
    shadow.fillColor = NSColor.black.withAlphaComponent(0.35)
    shadow.strokeColor = .clear
    shadow.position.y = -13
    node.addChild(body)
    let c = player ? hex(0x748f9a) : hex(regions[min(kind, 4)].color)
    let scale: CGFloat = boss ? 1.8 : player ? 1 : 0.9
    body.setScale(scale)
    radius = boss ? 31 : 17
    let cape = poly(
      [
        CGPoint(x: -17, y: 13), CGPoint(x: 16, y: 13), CGPoint(x: 23, y: -26),
        CGPoint(x: 3, y: -21), CGPoint(x: -22, y: -28),
      ], player ? hex(0x863e43) : c.withAlphaComponent(0.6), dark, 2)
    body.addChild(cape)
    at(rect(9, 18, hex(0x20212a), 2), -7, -15, body)
    at(rect(9, 18, hex(0x20212a), 2), 7, -15, body)
    let torso = poly(
      [
        CGPoint(x: -13, y: 13), CGPoint(x: 12, y: 13), CGPoint(x: 15, y: -4), CGPoint(x: 0, y: -13),
        CGPoint(x: -14, y: -4),
      ], c, dark, 2)
    body.addChild(torso)
    at(
      poly(
        [CGPoint(x: -9, y: 9), CGPoint(x: 0, y: 13), CGPoint(x: 8, y: 9), CGPoint(x: 0, y: -8)],
        c.blended(withFraction: 0.2, of: .white)!), 0, 0, body)
    at(circle(8, c, dark, 2), -16, 9, body)
    at(circle(8, c, dark, 2), 16, 9, body)
    let helm = poly(
      [
        CGPoint(x: -10, y: 26), CGPoint(x: 0, y: 32), CGPoint(x: 10, y: 26), CGPoint(x: 9, y: 13),
        CGPoint(x: 0, y: 8), CGPoint(x: -9, y: 13),
      ], player ? hex(0xb9c3bd) : c, dark, 2)
    body.addChild(helm)
    at(rect(15, 3, dark), 0, 21, body)
    at(rect(4, 2, player ? gold : hex(0xffded0)), 4, 21, body)
    at(rect(2, 16, c.blended(withFraction: 0.4, of: .white)!), 0, 24, body)
    if boss {
      if kind == 1 {
        for x in [-14.0, 0, 14] {
          let thorn = poly(
            [CGPoint(x: x - 4, y: 27), CGPoint(x: x - 10, y: 48), CGPoint(x: x + 3, y: 32)], c)
          body.addChild(thorn)
        }
      } else if kind == 3 {
        at(circle(25, .clear, c.withAlphaComponent(0.8), 2), 0, 24, body)
        at(circle(31, .clear, c.withAlphaComponent(0.35), 1), 0, 24, body)
      } else if kind == 4 {
        for i in 0..<9 {
          let a = CGFloat(i) * pi / 4.5
          let p = poly(
            [direction(a - 0.06) * 32, direction(a) * 48, direction(a + 0.06) * 32], gold)
          p.position.y = 20
          body.addChild(p)
        }
      } else {
        at(
          poly([CGPoint(x: -12, y: 27), CGPoint(x: -21, y: 44), CGPoint(x: -8, y: 35)], c), 0, 0,
          body)
        at(
          poly([CGPoint(x: 12, y: 27), CGPoint(x: 21, y: 44), CGPoint(x: 8, y: 35)], c), 0, 0, body)
      }
    }
    node.addChild(weapon)
    let blade = poly(
      [
        CGPoint(x: 20, y: -3), CGPoint(x: 59, y: -2), CGPoint(x: 68, y: 2), CGPoint(x: 58, y: 5),
        CGPoint(x: 20, y: 5),
      ], boss && kind == 1 ? hex(0x8fc99b) : hex(0xcbd2cc), dark, 1.5)
    weapon.addChild(blade)
    at(rect(4, 18, gold), 20, 1, weapon)
    at(rect(12, 5, hex(0x695348)), 12, 1, weapon)
    weapon.setScale(boss ? 1.25 : 0.82)
    if !player && !boss {
      let b = rect(34, 3, red)
      b.position.y = 43
      node.addChild(b)
      healthBar = b
    }
  }
}
struct Hazard {
  var node: SKNode
  var pos: CGPoint
  var age: CGFloat = 0
  var delay: CGFloat
  var duration: CGFloat
  var radius: CGFloat
  var damage: CGFloat
  var type: String
  var hit = false
}
struct Projectile {
  var node: SKNode
  var velocity: CGPoint
  var life: CGFloat
  var damage: CGFloat
  var radius: CGFloat
  var reflected = false
}
struct SaveData: Codable {
  var chapter = 0
  var cleared = false
  var embers = 0
  var vitality = 0
  var blade = 0
  var flask = 0
  var boons: [Int] = []
  var deaths = 0
  var easy = false
  var won = false
  var lostEmbers = 0
  var lostX: CGFloat = 0
  var lostY: CGFloat = 0

  init() {}

  init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: CodingKeys.self)
    chapter = try values.decodeIfPresent(Int.self, forKey: .chapter) ?? 0
    cleared = try values.decodeIfPresent(Bool.self, forKey: .cleared) ?? false
    embers = try values.decodeIfPresent(Int.self, forKey: .embers) ?? 0
    vitality = try values.decodeIfPresent(Int.self, forKey: .vitality) ?? 0
    blade = try values.decodeIfPresent(Int.self, forKey: .blade) ?? 0
    flask = try values.decodeIfPresent(Int.self, forKey: .flask) ?? 0
    boons = try values.decodeIfPresent([Int].self, forKey: .boons) ?? []
    deaths = try values.decodeIfPresent(Int.self, forKey: .deaths) ?? 0
    easy = try values.decodeIfPresent(Bool.self, forKey: .easy) ?? false
    won = try values.decodeIfPresent(Bool.self, forKey: .won) ?? false
    lostEmbers = try values.decodeIfPresent(Int.self, forKey: .lostEmbers) ?? 0
    lostX = try values.decodeIfPresent(CGFloat.self, forKey: .lostX) ?? 0
    lostY = try values.decodeIfPresent(CGFloat.self, forKey: .lostY) ?? 0
  }
}
