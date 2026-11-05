import AppKit
import Foundation
// Preserve the source. Crop only its existing tile margin and extend the paper
// underneath transparent corners; macOS supplies the one final outer mask.
let root = URL(fileURLWithPath: CommandLine.arguments[1])
guard let image = NSImage(contentsOf: root.appendingPathComponent("Resources/AppIcon-source.png")),
      let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: 1024, pixelsHigh: 1024,
                                bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                                isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0),
      let context = NSGraphicsContext(bitmapImageRep: rep) else { fatalError("Unable to load source icon") }
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = context
NSColor(calibratedRed: 1, green: 0.948, blue: 0.863, alpha: 1).setFill()
NSRect(x: 0, y: 0, width: 1024, height: 1024).fill()
context.imageInterpolation = .high
image.draw(in: NSRect(x: 0, y: 0, width: 1024, height: 1024),
           from: NSRect(x: 46, y: 54, width: 1140, height: 1140), operation: .sourceOver, fraction: 1)
NSGraphicsContext.restoreGraphicsState()
guard let png = rep.representation(using: .png, properties: [:]) else { fatalError("PNG encoding failed") }
try png.write(to: root.appendingPathComponent("Resources/ShellX.icon/Assets/Snail.png"))
