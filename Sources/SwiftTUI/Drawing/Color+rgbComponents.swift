import Foundation

extension Color {
    public var rgbComponents: (red: Int, green: Int, blue: Int)? {
        switch data {
        case .ansi(let ansiColor):
            return ansiColor.rgbComponents
        case .xterm(let xtermColor):
            return xtermColor.rgbComponents
        case .trueColor(let trueColor):
            return (trueColor.red, trueColor.green, trueColor.blue)
        }
    }
}

extension ANSIColor {
    var rgbComponents: (red: Int, green: Int, blue: Int)? {
        switch foregroundCode {
        case 30: // Black
            return (0, 0, 0)
        case 31: // Red
            return (205, 0, 0)
        case 32: // Green
            return (0, 205, 0)
        case 33: // Yellow
            return (205, 205, 0)
        case 34: // Blue
            return (0, 0, 238)
        case 35: // Magenta
            return (205, 0, 205)
        case 36: // Cyan
            return (0, 205, 205)
        case 37: // White
            return (229, 229, 229)
        case 90: // Bright Black (Gray)
            return (127, 127, 127)
        case 91: // Bright Red
            return (255, 0, 0)
        case 92: // Bright Green
            return (0, 255, 0)
        case 93: // Bright Yellow
            return (255, 255, 0)
        case 94: // Bright Blue
            return (92, 92, 255)
        case 95: // Bright Magenta
            return (255, 0, 255)
        case 96: // Bright Cyan
            return (0, 255, 255)
        case 97: // Bright White
            return (255, 255, 255)
        default:
            return nil
        }
    }
}

extension XTermColor {
    var rgbComponents: (red: Int, green: Int, blue: Int)? {
        let value = self.value
        if value >= 16 && value <= 231 {
            // Color cube (216 colors)
            let index = value - 16
            let r = index / 36
            let g = (index % 36) / 6
            let b = index % 6
            // Each component ranges from 0 to 5; scale to 0-255
            let red = r * 51
            let green = g * 51
            let blue = b * 51
            return (red, green, blue)
        } else if value >= 232 && value <= 255 {
            // Grayscale (24 shades)
            let gray = value - 232
            // Grayscale levels from 8 to 238 in steps of 10
            let level = 8 + gray * 10
            return (level, level, level)
        } else {
            // System colors or invalid values
            return nil
        }
    }
}
