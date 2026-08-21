import CoreGraphics
import Foundation
import ImageIO

guard CommandLine.arguments.count == 4,
      let size = Int(CommandLine.arguments[3]),
      let source = CGImageSourceCreateWithURL(URL(fileURLWithPath: CommandLine.arguments[1]) as CFURL, nil),
      let logo = CGImageSourceCreateImageAtIndex(source, 0, nil),
      let context = CGContext(
          data: nil,
          width: size,
          height: size,
          bitsPerComponent: 8,
          bytesPerRow: size * 4,
          space: CGColorSpaceCreateDeviceRGB(),
          bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
      ) else {
    exit(1)
}

context.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
let radius = CGFloat(size) * 0.22
context.addPath(CGPath(roundedRect: CGRect(x: 0, y: 0, width: size, height: size), cornerWidth: radius, cornerHeight: radius, transform: nil))
context.fillPath()

let logoInset = CGFloat(size) * 0.12
context.draw(logo, in: CGRect(x: logoInset, y: logoInset, width: CGFloat(size) - logoInset * 2, height: CGFloat(size) - logoInset * 2))

guard let image = context.makeImage(),
      let destination = CGImageDestinationCreateWithURL(URL(fileURLWithPath: CommandLine.arguments[2]) as CFURL, "public.png" as CFString, 1, nil) else {
    exit(1)
}
CGImageDestinationAddImage(destination, image, nil)
guard CGImageDestinationFinalize(destination) else { exit(1) }