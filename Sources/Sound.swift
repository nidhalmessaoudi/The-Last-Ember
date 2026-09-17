import AVFoundation
import Foundation

final class Sound {
  let engine = AVAudioEngine()
  let ambient = AVAudioPlayerNode()
  var enabled = true
  var voices: [AVAudioPlayerNode] = []
  var index = 0
  init() {
    if CommandLine.arguments.contains("--self-test") { return }
    engine.attach(ambient)
    let fmt = AVAudioFormat(standardFormatWithSampleRate: 22050, channels: 1)!
    engine.connect(ambient, to: engine.mainMixerNode, format: fmt)
    for _ in 0..<12 {
      let p = AVAudioPlayerNode()
      engine.attach(p)
      engine.connect(p, to: engine.mainMixerNode, format: fmt)
      voices.append(p)
    }
    engine.mainMixerNode.outputVolume = 0.55
    do {
      try engine.start()
      let b = AVAudioPCMBuffer(pcmFormat: fmt, frameCapacity: 22050 * 8)!
      b.frameLength = b.frameCapacity
      for i in 0..<Int(b.frameLength) {
        let t = Double(i) / 22050
        let fade = sin(Double.pi * Double(i) / Double(b.frameLength))
        b.floatChannelData![0][i] = Float(
          (sin(t * 2 * Double.pi * 55) * 0.045 + sin(t * 2 * Double.pi * 82.5) * 0.02 + sin(
            t * 2 * Double.pi * 110) * 0.012) * fade * fade)
      }
      ambient.scheduleBuffer(b, at: nil, options: .loops)
      ambient.play()
    } catch {}
  }
  func toggle() {
    enabled.toggle()
    engine.mainMixerNode.outputVolume = enabled ? 0.55 : 0
  }
  func play(_ kind: String) {
    if voices.isEmpty { return }
    let p = voices[index % voices.count]
    index += 1
    p.stop()
    let duration: Double =
      kind == "boss"
      ? 1.4 : kind == "death" ? 1.1 : kind == "parry" ? 0.5 : kind == "heal" ? 0.65 : 0.22
    let fmt = AVAudioFormat(standardFormatWithSampleRate: 22050, channels: 1)!
    let b = AVAudioPCMBuffer(pcmFormat: fmt, frameCapacity: UInt32(22050 * duration))!
    b.frameLength = b.frameCapacity
    for i in 0..<Int(b.frameLength) {
      let t = Double(i) / 22050
      let e = pow(1 - t / duration, 2)
      let noise = Double.random(in: -1...1)
      var v: Double = 0
      switch kind {
      case "hit": v = (sin(t * (180 - t * 450) * 6.28) * 0.4 + noise * 0.24) * e
      case "swing": v = noise * 0.18 * e * sin(min(1, t * 25) * 1.57)
      case "roll": v = noise * 0.1 * e
      case "parry": v = (sin(t * 1760 * 6.28) + sin(t * 2640 * 6.28) * 0.5) * e * 0.2
      case "heal": v = (sin(t * (440 + t * 330) * 6.28) + sin(t * 660 * 6.28)) * e * 0.1
      case "boss": v = (sin(t * 55 * 6.28) + sin(t * 82.4 * 6.28) + noise * 0.2) * e * 0.15
      case "death": v = sin(t * (130 - t * 60) * 6.28) * e * 0.24
      case "win":
        v = (sin(t * 440 * 6.28) + sin(t * 554.36 * 6.28) + sin(t * 659.25 * 6.28)) * e * 0.12
      default: v = sin(t * 660 * 6.28) * e * 0.1
      }
      b.floatChannelData![0][i] = Float(v)
    }
    p.scheduleBuffer(b)
    p.play()
  }
}
