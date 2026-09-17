import AVFoundation
import AppKit
import Foundation
import SpriteKit

let pi = CGFloat.pi
func clamp(_ x: CGFloat, _ a: CGFloat, _ b: CGFloat) -> CGFloat { min(b, max(a, x)) }
func length(_ p: CGPoint) -> CGFloat { hypot(p.x, p.y) }
func + (a: CGPoint, b: CGPoint) -> CGPoint { CGPoint(x: a.x + b.x, y: a.y + b.y) }
func - (a: CGPoint, b: CGPoint) -> CGPoint { CGPoint(x: a.x - b.x, y: a.y - b.y) }
func * (a: CGPoint, b: CGFloat) -> CGPoint { CGPoint(x: a.x * b, y: a.y * b) }
func unit(_ p: CGPoint) -> CGPoint {
  let d = length(p)
  return d > 0.001 ? p * (1 / d) : CGPoint(x: 1, y: 0)
}
func direction(_ a: CGFloat) -> CGPoint { CGPoint(x: cos(a), y: sin(a)) }
func angle(_ p: CGPoint) -> CGFloat { atan2(p.y, p.x) }
func dist(_ a: CGPoint, _ b: CGPoint) -> CGFloat { length(a - b) }
func hex(_ h: UInt32, _ a: CGFloat = 1) -> NSColor {
  NSColor(
    calibratedRed: CGFloat((h >> 16) & 255) / 255, green: CGFloat((h >> 8) & 255) / 255,
    blue: CGFloat(h & 255) / 255, alpha: a)
}
let ivory = hex(0xeee5cd)
let gold = hex(0xe7b96b)
let dark = hex(0x0c1118)
let red = hex(0xc84c54)
func shape(_ path: CGPath, _ fill: NSColor, _ stroke: NSColor = .clear, _ width: CGFloat = 1)
  -> SKShapeNode
{
  let n = SKShapeNode(path: path)
  n.fillColor = fill
  n.strokeColor = stroke
  n.lineWidth = width
  return n
}
func poly(_ pts: [CGPoint], _ fill: NSColor, _ stroke: NSColor = .clear, _ width: CGFloat = 1)
  -> SKShapeNode
{
  let p = CGMutablePath()
  if let f = pts.first {
    p.move(to: f)
    for v in pts.dropFirst() { p.addLine(to: v) }
    p.closeSubpath()
  }
  return shape(p, fill, stroke, width)
}
func circle(_ r: CGFloat, _ fill: NSColor, _ stroke: NSColor = .clear, _ width: CGFloat = 1)
  -> SKShapeNode
{
  let n = SKShapeNode(circleOfRadius: r)
  n.fillColor = fill
  n.strokeColor = stroke
  n.lineWidth = width
  return n
}
func rect(_ w: CGFloat, _ h: CGFloat, _ fill: NSColor, _ radius: CGFloat = 0) -> SKShapeNode {
  let n = SKShapeNode(rectOf: CGSize(width: w, height: h), cornerRadius: radius)
  n.fillColor = fill
  n.strokeColor = .clear
  return n
}
func label(
  _ text: String, _ size: CGFloat = 18, _ color: NSColor = ivory,
  _ font: String = "AvenirNext-Medium"
) -> SKLabelNode {
  let n = SKLabelNode(fontNamed: font)
  n.text = text
  n.fontSize = size
  n.fontColor = color
  n.verticalAlignmentMode = .center
  return n
}
@discardableResult func at(_ n: SKNode, _ x: CGFloat, _ y: CGFloat, _ parent: SKNode) -> SKNode {
  n.position = CGPoint(x: x, y: y)
  parent.addChild(n)
  return n
}
func glowTexture() -> SKTexture {
  let s = 128
  let image = NSImage(size: NSSize(width: s, height: s))
  image.lockFocus()
  let g = NSGradient(colors: [
    NSColor.white.withAlphaComponent(0.65), NSColor.white.withAlphaComponent(0.12), NSColor.clear,
  ])!
  g.draw(
    in: NSBezierPath(ovalIn: NSRect(x: 0, y: 0, width: s, height: s)), relativeCenterPosition: .zero
  )
  image.unlockFocus()
  return SKTexture(image: image)
}
let glowTex = glowTexture()
func glow(_ radius: CGFloat, _ color: NSColor) -> SKSpriteNode {
  let n = SKSpriteNode(
    texture: glowTex, color: color, size: CGSize(width: radius * 2, height: radius * 2))
  n.colorBlendFactor = 1
  n.blendMode = .add
  return n
}
