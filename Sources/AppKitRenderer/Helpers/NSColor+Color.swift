import SwiftTUI
import AppKit

extension NSColor {
    /// Initializes an `NSColor` from a `Color`, using its RGB components.
    /// Returns `nil` if the color cannot be represented as RGB.
    convenience init?(_ color: Color) {
        guard let rgb = color.rgbComponents else {
            return nil
        }
        self.init(
            calibratedRed: CGFloat(rgb.red) / 255.0,
            green: CGFloat(rgb.green) / 255.0,
            blue: CGFloat(rgb.blue) / 255.0,
            alpha: 1
        )
    }
}
