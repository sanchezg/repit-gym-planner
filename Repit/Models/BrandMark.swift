// Copyright (C) 2026 gsanz.dev
// Licensed under GNU GPL version 3 only, with the additional notice-preservation
// term in ATTRIBUTION.md. See LICENSE and ATTRIBUTION.md.

import CoreGraphics

/// Shared vector geometry for the app icon, interface symbol, and SVG export.
enum BrandMark {
    private enum Segment: Sendable {
        case move(CGFloat, CGFloat)
        case line(CGFloat, CGFloat)
        case curve(CGFloat, CGFloat, CGFloat, CGFloat, CGFloat, CGFloat)
        case close
    }

    private static let segments: [Segment] = [
        .move(64, 0), .line(282, 0),
        .curve(458, 0, 548, 78, 548, 214),
        .curve(548, 304, 508, 366, 438, 400),
        .line(548, 540),
        .curve(570, 568, 550, 600, 516, 600),
        .line(474, 600),
        .curve(455, 600, 442, 592, 430, 576),
        .line(306, 416), .line(132, 416), .line(132, 536),
        .curve(132, 576, 108, 600, 68, 600),
        .line(64, 600),
        .curve(24, 600, 0, 576, 0, 536),
        .line(0, 64),
        .curve(0, 24, 24, 0, 64, 0), .close,
        .move(132, 132), .line(276, 132),
        .curve(366, 132, 408, 158, 408, 214),
        .curve(408, 268, 368, 284, 276, 284),
        .line(132, 284), .close
    ]

    private static var outline: CGPath {
        let path = CGMutablePath()
        for segment in segments {
            switch segment {
            case let .move(x, y): path.move(to: CGPoint(x: x, y: y))
            case let .line(x, y): path.addLine(to: CGPoint(x: x, y: y))
            case let .curve(x1, y1, x2, y2, x, y):
                path.addCurve(to: CGPoint(x: x, y: y), control1: CGPoint(x: x1, y: y1), control2: CGPoint(x: x2, y: y2))
            case .close: path.closeSubpath()
            }
        }
        return path
    }

    static func path(in rect: CGRect) -> CGPath {
        let path = outline
        let bounds = path.boundingBoxOfPath
        let scale = min(rect.width / bounds.width, rect.height / bounds.height)
        var transform = CGAffineTransform(a: scale, b: 0, c: 0, d: scale,
                                         tx: rect.midX - bounds.midX * scale, ty: rect.midY - bounds.midY * scale)
        return path.copy(using: &transform)!
    }

    static var svgPathData: String {
        segments.map { segment in
            switch segment {
            case let .move(x, y): "M\(Int(x)) \(Int(y))"
            case let .line(x, y): "L\(Int(x)) \(Int(y))"
            case let .curve(x1, y1, x2, y2, x, y): "C\(Int(x1)) \(Int(y1)) \(Int(x2)) \(Int(y2)) \(Int(x)) \(Int(y))"
            case .close: "Z"
            }
        }.joined(separator: " ")
    }
}
