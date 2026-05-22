import AppKit
import ImageIO
import UniformTypeIdentifiers

// Generates the STOIC OS app icon — a HUD command-center mark.

let side: CGFloat = 1024
let space = CGColorSpaceCreateDeviceRGB()
guard let ctx = CGContext(data: nil, width: Int(side), height: Int(side),
                          bitsPerComponent: 8, bytesPerRow: 0, space: space,
                          bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
    fatalError("context")
}

ctx.clear(CGRect(x: 0, y: 0, width: side, height: side))

let cyan = CGColor(red: 0.38, green: 0.86, blue: 1.0, alpha: 1)
let gold = CGColor(red: 1.0, green: 0.78, blue: 0.34, alpha: 1)
let center = CGPoint(x: side / 2, y: side / 2)

// Rounded-rect body.
let margin: CGFloat = 100
let body = CGRect(x: margin, y: margin, width: side - 2 * margin, height: side - 2 * margin)
let bodyPath = CGPath(roundedRect: body, cornerWidth: 185, cornerHeight: 185, transform: nil)

ctx.saveGState()
ctx.addPath(bodyPath)
ctx.clip()
let bg = CGGradient(colorsSpace: space,
                    colors: [CGColor(red: 0.03, green: 0.04, blue: 0.07, alpha: 1),
                             CGColor(red: 0.07, green: 0.10, blue: 0.17, alpha: 1)] as CFArray,
                    locations: [0, 1])!
ctx.drawLinearGradient(bg,
                       start: CGPoint(x: margin, y: side - margin),
                       end: CGPoint(x: side - margin, y: margin),
                       options: [])
ctx.restoreGState()

// Central glowing ring.
ctx.setShadow(offset: .zero, blur: 55, color: cyan.copy(alpha: 0.85))
ctx.setStrokeColor(cyan)
ctx.setLineWidth(36)
ctx.addArc(center: center, radius: 232, startAngle: 0, endAngle: .pi * 2, clockwise: false)
ctx.strokePath()

// Gold command core.
ctx.setShadow(offset: .zero, blur: 44, color: gold.copy(alpha: 0.85))
ctx.setFillColor(gold)
ctx.addArc(center: center, radius: 68, startAngle: 0, endAngle: .pi * 2, clockwise: false)
ctx.fillPath()
ctx.setShadow(offset: .zero, blur: 0, color: nil)

// HUD corner brackets.
ctx.setStrokeColor(cyan.copy(alpha: 0.9) ?? cyan)
ctx.setLineWidth(24)
ctx.setLineCap(.square)
ctx.setLineJoin(.miter)
let inset = margin + 78
let length: CGFloat = 132
let lo = inset
let hi = side - inset

func bracket(at corner: CGPoint, dx: CGFloat, dy: CGFloat) {
    ctx.move(to: CGPoint(x: corner.x, y: corner.y + dy * length))
    ctx.addLine(to: corner)
    ctx.addLine(to: CGPoint(x: corner.x + dx * length, y: corner.y))
}
bracket(at: CGPoint(x: lo, y: hi), dx: 1, dy: -1)
bracket(at: CGPoint(x: hi, y: hi), dx: -1, dy: -1)
bracket(at: CGPoint(x: hi, y: lo), dx: -1, dy: 1)
bracket(at: CGPoint(x: lo, y: lo), dx: 1, dy: 1)
ctx.strokePath()

guard let image = ctx.makeImage() else { fatalError("image") }
let outURL = URL(fileURLWithPath: "icon_1024.png")
guard let dest = CGImageDestinationCreateWithURL(outURL as CFURL,
                                                 UTType.png.identifier as CFString, 1, nil) else {
    fatalError("destination")
}
CGImageDestinationAddImage(dest, image, nil)
CGImageDestinationFinalize(dest)
print("wrote icon_1024.png")
