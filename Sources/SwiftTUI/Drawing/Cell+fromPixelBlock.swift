import Foundation

extension Cell {
    typealias ColorChannels = (Int, Int, Int)

    /// Builds a `Cell` object that represents the contents of the given _pixel block_ in the given color mode.
    /// Based on Stefan Haustein's `TerminalImageViewer.java` -- original license: Apache 2.0.
    static func fromPixelBlock(_ pixels: Image.PixelBlock, colorMode: ColorMode) -> Cell {
        // Initialize min and max arrays
        let height = pixels.count
        let width = pixels[0].count

        assert(height == Image.pixelBlockSize.height)
        assert(width == Image.pixelBlockSize.width)

        // Determine min and max for each color channel
        let (minColor, maxColor) = colorRange(pixels)

        // Determine the channel with the greatest range
        let (splitIndex, bestSplit) = greatestRangeChannel(minColor: minColor, maxColor: maxColor)
        
        // Compute the split value
        let splitValue = minColor[splitIndex] + bestSplit / 2
        
        // Compute average colors and bitmap
        var (fgChannels, fgCount, bgChannels, _, bits) = averageColors(pixels: pixels, splitIndex: splitIndex, splitValue: splitValue)
        
        // After computing fgColor and bgColor, find best matching character
        let bestChar = bestMatchingCharacter(
            bits: bits,
            width: width,
            height: height,
            fgCount: fgCount,
            fgChannels: &fgChannels,
            bgChannels: &bgChannels,
            colorMode: colorMode
        )
        
        // Create Colors based on the color mode
        let (fgColor, bgColor) = buildColor(fgChannels: fgChannels, bgChannels: bgChannels, colorMode: colorMode)
        
        // Create a Cell
        return Cell(
            char: bestChar,
            foregroundColor: fgColor,
            backgroundColor: bgColor,
            attributes: CellAttributes()
        )
    }
    
    /// Helper function to compute xterm 256-color value
    private static func xterm256ColorValue(r: Int, g: Int, b: Int) -> Int {
        let rValue = r * 5 / 255
        let gValue = g * 5 / 255
        let bValue = b * 5 / 255
        return 16 + 36 * rValue + 6 * gValue + bValue
    }
    
    private static func toGrayscale(_ color: ColorChannels) -> ColorChannels {
        let gray = Int(0.299 * Double(color.0) + 0.587 * Double(color.1) + 0.114 * Double(color.2))
        return (gray, gray, gray)
    }
    
    private static func to256Color(_ color: ColorChannels) -> ColorChannels {
        let r = color.0 * 5 / 255
        let g = color.1 * 5 / 255
        let b = color.2 * 5 / 255
        let mappedColor = (
            r * 255 / 5,
            g * 255 / 5,
            b * 255 / 5
        )
        return mappedColor
    }
    
    private static func hammingDistance(_ a: Image.PixelBlockBitmap, _ b: Image.PixelBlockBitmap) -> Int {
        let xor = a ^ b
        return xor.nonzeroBitCount
    }
    
    private static func colorRange(_ pixels: Image.PixelBlock) -> (min:[Int], max:[Int]) {
        // Initialize min and max arrays
        var minColor = [255, 255, 255]
        var maxColor = [0, 0, 0]

        // Determine min and max for each color channel
        for row in pixels {
            for pixel in row {
                for i in 0..<3 {
                    let value = pixel[i]
                    if value < minColor[i] {
                        minColor[i] = value
                    }
                    if value > maxColor[i] {
                        maxColor[i] = value
                    }
                }
            }
        }
        
        return (min: minColor, max: maxColor)
    }
    
    private static func greatestRangeChannel(minColor: [Int], maxColor: [Int]) -> (index: Int, range: Int) {
        var splitIndex = 0
        var bestSplit = 0
        for i in 0..<3 {
            let range = maxColor[i] - minColor[i]
            if range > bestSplit {
                bestSplit = range
                splitIndex = i
            }
        }
        return (index: splitIndex, range: bestSplit)
    }
    
    private static func averageColors(
        pixels: Image.PixelBlock,
        splitIndex: Int,
        splitValue: Int
    ) -> (foreground: ColorChannels, foregroundCount: Int, background: ColorChannels, backgroundCount: Int, bits: Image.PixelBlockBitmap) {
        // Initialize the bits, foreground and background colors
        var bits: Image.PixelBlockBitmap = 0
        var fgColorSum = [0, 0, 0]
        var bgColorSum = [0, 0, 0]
        var fgCount = 0
        var bgCount = 0
        
        // Assign pixels to foreground or background and build the bits
        for row in pixels {
            for pixel in row {
                bits <<= 1
                let value = pixel[splitIndex]
                if value > splitValue {
                    // Foreground
                    bits |= 1
                    for i in 0..<3 {
                        fgColorSum[i] += pixel[i]
                    }
                    fgCount += 1
                } else {
                    // Background
                    for i in 0..<3 {
                        bgColorSum[i] += pixel[i]
                    }
                    bgCount += 1
                }
            }
        }
        
        // Compute average colors
        if fgCount > 0 {
            for i in 0..<3 {
                fgColorSum[i] /= fgCount
            }
        }
        if bgCount > 0 {
            for i in 0..<3 {
                bgColorSum[i] /= bgCount
            }
        }
        
        // Foreground and background colors
        let fgChannels = (fgColorSum[0], fgColorSum[1], fgColorSum[2])
        let bgChannels = (bgColorSum[0], bgColorSum[1], bgColorSum[2])
        
        return (
            foreground: fgChannels,
            foregroundCount: fgCount,
            background: bgChannels,
            backgroundCount: bgCount,
            bits: bits
        )
    }
    
    private static func bestMatchingCharacter(
        bits: Image.PixelBlockBitmap,
        width: Int,
        height: Int,
        fgCount: Int,
        fgChannels: inout ColorChannels,
        bgChannels: inout ColorChannels,
        colorMode: ColorMode
    ) -> Character {
        // Adjust fgColor and bgColor based on the color mode
        switch colorMode {
        case .grayscale:
            fgChannels = toGrayscale(fgChannels)
            bgChannels = toGrayscale(bgChannels)
        case .color256:
            fgChannels = to256Color(fgChannels)
            bgChannels = to256Color(bgChannels)
        case .trueColor:
            // No adjustment needed
            break
        }
        
        // Now, find the best matching character
        var bestDiff = Int.max
        var bestChar: Character = " "
        var invert = false
        
        for (bitmap, char) in Character.bitmaps {
            let diff = hammingDistance(bits, bitmap)
            if diff < bestDiff {
                bestDiff = diff
                bestChar = char
                invert = false
            }
            let invertedBitmap = ~bitmap
            let diffInverted = hammingDistance(bits, invertedBitmap)
            if diffInverted < bestDiff {
                bestDiff = diffInverted
                bestChar = char
                invert = true
            }
        }
        
        // If the match is quite bad, use a shade character instead
        if bestDiff > 10 {
            invert = false
            let totalPixels = width * height
            let index = min(4, fgCount * 5 / totalPixels)
            let shadeChars = [" ", "\u{2591}", "\u{2592}", "\u{2593}", "\u{2588}"]
            bestChar = Character(shadeChars[index])
        }
        
        // If we use an inverted character, swap fg and bg colors
        if invert {
            swap(&fgChannels, &bgChannels)
        }
        
        return bestChar
    }
    
    private static func buildColor(
        fgChannels: ColorChannels,
        bgChannels: ColorChannels,
        colorMode: ColorMode
    ) -> (foreground: Color, background: Color) {
        switch colorMode {
        case .grayscale:
            let grayValueFG = fgChannels.0 * 23 / 255  // Map 0-255 to 0-23
            let grayValueBG = bgChannels.0 * 23 / 255
            return (
                foreground: Color.xterm(white: grayValueFG),
                background: Color.xterm(white: grayValueBG)
            )
            
        case .color256:
            let colorValueFG = xterm256ColorValue(r: fgChannels.0, g: fgChannels.1, b: fgChannels.2)
            let colorValueBG = xterm256ColorValue(r: bgChannels.0, g: bgChannels.1, b: bgChannels.2)
            return (
                foreground: Color.xtermColor(value: colorValueFG),
                background: Color.xtermColor(value: colorValueBG)
            )
            
        case .trueColor:
            return (
                foreground: Color.trueColor(red: fgChannels.0, green: fgChannels.1, blue: fgChannels.2),
                background: Color.trueColor(red: bgChannels.0, green: bgChannels.1, blue: bgChannels.2)
            )
        }
    }
}

extension TrueColor {
    fileprivate subscript(_ channel: Int) -> Int {
        if channel == 0 {
            return red
        } else if channel == 1 {
            return green
        } else if channel == 2 {
            return blue
        } else {
            fatalError("Invalid color channel: \(channel)")
        }
    }
}
