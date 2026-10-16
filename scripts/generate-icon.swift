// Copyright (C) 2026 gsanz.dev
// Licensed under GNU GPL version 3 only, with the additional notice-preservation
// term in ATTRIBUTION.md. See LICENSE and ATTRIBUTION.md.

import AppKit

@main struct GenerateIcon {
    static func main() throws {
        guard CommandLine.arguments.count >= 2 else {
            fatalError("Usage: generate-icon OUTPUT.png [SYMBOL.svg]")
        }
        let size = 1024
        let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
        let context = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8,
                                bytesPerRow: size * 4, space: colorSpace,
                                bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
        context.setFillColor(CGColor(srgbRed: 0.055, green: 0.065, blue: 0.06, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: size, height: size))
        context.setAllowsAntialiasing(true)
        context.setShouldAntialias(true)
        context.translateBy(x: 0, y: CGFloat(size))
        context.scaleBy(x: 1, y: -1)
        context.setFillColor(CGColor(srgbRed: 0.80, green: 0.96, blue: 0.42, alpha: 1))
        context.addPath(BrandMark.path(in: CGRect(x: 232, y: 208, width: 560, height: 608)))
        context.drawPath(using: .eoFill)
        let image = context.makeImage()!
        let bitmap = NSBitmapImageRep(cgImage: image)
        let png = bitmap.representation(using: .png, properties: [:])!
        try png.write(to: URL(fileURLWithPath: CommandLine.arguments[1]))

        if CommandLine.arguments.count > 2 {
            let svg = """
            <!-- Copyright (C) 2026 gsanz.dev; GNU GPL version 3 only. See LICENSE and ATTRIBUTION.md. -->
            <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 560 600" fill="none">
              <title>repit symbol</title>
              <path fill="#CCF56B" fill-rule="evenodd" d="\(BrandMark.svgPathData)"/>
            </svg>
            """
            try svg.write(to: URL(fileURLWithPath: CommandLine.arguments[2]), atomically: true, encoding: .utf8)
        }
        print("Generated opaque 1024 × 1024 app icon from shared vector geometry.")
    }
}
