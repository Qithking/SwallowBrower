//
//  NSImage+DominantColor.swift
//  SwallowBrower
//
//  Created by thking on 2026/4/12.
//

import AppKit

extension NSBitmapImageRep {
    func dominantColor(excludeWhiteAndBlack: Bool = true) -> NSColor? {
        var colorCounts: [String: (r: UInt8, g: UInt8, b: UInt8, count: Int)] = [:]
        
        for x in 0..<pixelsWide {
            for y in 0..<pixelsHigh {
                guard let color = colorAt(x: x, y: y) else { continue }
                
                if color.alphaComponent < 0.5 { continue }
                
                let r = UInt8(color.redComponent * 255)
                let g = UInt8(color.greenComponent * 255)
                let b = UInt8(color.blueComponent * 255)
                
                if excludeWhiteAndBlack {
                    let brightness = (Double(r) + Double(g) + Double(b)) / 3.0 / 255.0
                    if brightness > 0.95 || brightness < 0.05 { continue }
                }
                
                // 量化到 32 级以减少颜色数量
                let qr = (r / 32) * 32
                let qg = (g / 32) * 32
                let qb = (b / 32) * 32
                let key = "\(qr),\(qg),\(qb)"
                
                if var existing = colorCounts[key] {
                    existing.count += 1
                    colorCounts[key] = existing
                } else {
                    colorCounts[key] = (qr, qg, qb, 1)
                }
            }
        }
        
        return colorCounts.values.max(by: { $0.count < $1.count })
            .map { NSColor(calibratedRed: CGFloat($0.r) / 255.0,
                          green: CGFloat($0.g) / 255.0,
                          blue: CGFloat($0.b) / 255.0,
                          alpha: 1.0) }
    }
}
