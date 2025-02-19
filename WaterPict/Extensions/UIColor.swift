//
//  UIColor.swift
//  WaterPic
//
//  Created by Marius Bringsvor Rusten on 30/12/2024.
//

import UIKit

extension UIColor {

    convenience init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }

        let red = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
        let green = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
        let blue = CGFloat(rgb & 0x0000FF) / 255.0
        let alpha: CGFloat

        if hexSanitized.count == 8 {
            alpha = CGFloat((rgb & 0xFF000000) >> 24) / 255.0
        } else {
            alpha = 1.0
        }

        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }

    func toHex(alpha: Bool = false) -> String? {
        guard let components = cgColor.components, components.count >= 3 else { return nil }

        let red = Float(components[0])
        let green = Float(components[1])
        let blue = Float(components[2])
        let alphaValue = Float(components.count >= 4 ? components[3] : 1.0)

        if alpha {
            return String(format: "#%02lX%02lX%02lX%02lX",
                          lroundf(red * 255),
                          lroundf(green * 255),
                          lroundf(blue * 255),
                          lroundf(alphaValue * 255))
        } else {
            return String(format: "#%02lX%02lX%02lX",
                          lroundf(red * 255),
                          lroundf(green * 255),
                          lroundf(blue * 255))
        }
    }
}
