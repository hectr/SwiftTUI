#if canImport(SwiftUI) && canImport(Combine)
import Foundation
import Combine
import struct SwiftUI.Color
import struct SwiftUI.AttributedString
import struct SwiftUI.Font

@available(macOS 12, *)
public class AttributedStringRenderer: Renderer {
    public weak var application: Application?

    /// The size of the _virtual_ window.
    public var windowSize: Size {
        didSet {
            handleWindowSizeChange()
        }
    }

    private var layer: Layer?

    /// The rendered output as an `AttributedString` publisher.
    public let output = CurrentValueSubject<AttributedString, Never>(AttributedString(""))

    /// Cache to store the rendered cells
    private var cache: [[Cell?]] = []

    public init(windowSize: Size = Size(width: 80, height: 25)) {
        self.windowSize = windowSize
    }

    public func start(with layer: Layer) {
        self.layer = layer
        updateWindowSize()
        self.layer?.renderer = self
    }

    public func update() {
        if let invalidated = layer?.invalidated {
            draw(rect: invalidated)
            layer?.invalidated = nil
        }
    }

    public func stop() {
        output.send(AttributedString())
    }

    public func handleWindowSizeChange() {
        updateWindowSize()
        layer?.invalidate()
        application?.control.layout(size: layer?.frame.size ?? .zero) // Update control layout
        update()
    }

    /// Draw a specific area, or the entire layer if the area is nil.
    private func draw(rect: Rect? = nil) {
        guard let layer else {
            assertionFailure("Attempting to draw before layer is set")
            return
        }
        let rect = rect ?? Rect(position: .zero, size: layer.frame.size)
        guard rect.size.width > 0, rect.size.height > 0 else { return }

        // Build the attributed string
        var attributedString = AttributedString()

        for line in 0 ..< layer.frame.size.height.intValue {
            for column in 0 ..< layer.frame.size.width.intValue {
                let position = Position(column: Extended(column), line: Extended(line))
                if let cell = layer.cell(at: position) {
                    var char = AttributedString(String(cell.char))
                    let attributes = self.attributes(for: cell)
                    char.mergeAttributes(attributes)
                    attributedString.append(char)
                } else {
                    // Append a space if there's no cell at this position
                    attributedString.append(AttributedString(" "))
                }
            }
            // Add newline at the end of each line except the last
            if line < layer.frame.size.height.intValue - 1 {
                attributedString.append(AttributedString("\n"))
            }
        }

        // Update the output
        output.send(attributedString)
    }

    private func attributes(for cell: Cell) -> AttributeContainer {
        var attributes = AttributeContainer()

        // Set monospace font
        var font = Font.system(.body, design: .monospaced)

        // Handle font traits
        if cell.attributes.bold {
            font = font.weight(.bold)
        }
        if cell.attributes.italic {
            font = font.italic()
        }

        attributes.font = font

        // Handle colors
        if let fgColor = cell.foregroundColor.swiftUIColor {
            attributes.foregroundColor = fgColor
        }
        if let bgColor = (cell.backgroundColor ?? .default).swiftUIColor {
            attributes.backgroundColor = bgColor
        }
        if cell.attributes.inverted {
            let fgColor = attributes.foregroundColor ?? Color.black
            let bgColor = attributes.backgroundColor ?? Color.white
            attributes.foregroundColor = bgColor
            attributes.backgroundColor = fgColor
        }

        // Handle styles
        if cell.attributes.underline {
            attributes.underlineStyle = .single
        }
        if cell.attributes.strikethrough {
            attributes.strikethroughStyle = .single
        }

        return attributes
    }

    private func updateWindowSize() {
        if let layer {
            // Set the size from windowSize
            layer.frame.size = windowSize
            // Ensure the cache size matches the layer size
            setCache(for: layer)
        }
    }

    private func setCache(for layer: Layer) {
        cache = .init(
            repeating: .init(repeating: nil, count: layer.frame.size.width.intValue),
            count: layer.frame.size.height.intValue
        )
    }
}

@available(macOS 12, *)
extension Color {
    var swiftUIColor: SwiftUI.Color? {
        switch data {
        case .ansi(let ansiColor):
            return ansiColor.swiftUIColor
        case .xterm(let xtermColor):
            return xtermColor.swiftUIColor
        case .trueColor(let trueColor):
            return trueColor.swiftUIColor
        }
    }
}

@available(macOS 12, *)
extension ANSIColor {
    var swiftUIColor: SwiftUI.Color? {
        switch self {
        case .black: return .black
        case .red: return .red
        case .green: return .green
        case .yellow: return .yellow
        case .blue: return .blue
        case .magenta: return .purple
        case .cyan: return .cyan
        case .white: return .white
        case .brightBlack: return .gray
        case .brightRed: return .red
        case .brightGreen: return .green
        case .brightYellow: return .yellow
        case .brightBlue: return .blue
        case .brightMagenta: return .pink
        case .brightCyan: return .teal
        case .brightWhite: return .white
        default: return nil
        }
    }
}

@available(macOS 12, *)
extension XTermColor {
    var swiftUIColor: SwiftUI.Color? {
        if value < 16 {
            // Standard colors
            return XTermColor.standardColors[value]
        } else if value < 232 {
            // 6x6x6 color cube
            let idx = value - 16
            let r = idx / 36
            let g = (idx % 36) / 6
            let b = idx % 6

            // Each component is in the range 0-5
            // Convert to RGB by multiplying by 51 (since 255 / 5 = 51)
            let red = Double(r) * 51.0 / 255.0
            let green = Double(g) * 51.0 / 255.0
            let blue = Double(b) * 51.0 / 255.0

            return SwiftUI.Color(red: red, green: green, blue: blue)
        } else if value < 256 {
            // Grayscale colors
            // Gray levels from black to white in 24 steps
            let level = Double(value - 232) / 23.0
            return SwiftUI.Color(white: level)
        } else {
            // Invalid code
            return nil
        }
    }

    private static let standardColors: [SwiftUI.Color] = [
        // 0-7: Standard colors
        .black,                  // 0: Black
        .red,                    // 1: Red
        .green,                  // 2: Green
        .yellow,                 // 3: Yellow
        .blue,                   // 4: Blue
        .purple,                // 5: Magenta
        .cyan,                   // 6: Cyan
        .white,                  // 7: White
        // 8-15: High-intensity colors (bright versions)
        .gray,                   // 8: Bright Black (Gray)
        .red,                    // 9: Bright Red
        .green,                  // 10: Bright Green
        .yellow,                 // 11: Bright Yellow
        .blue,                   // 12: Bright Blue
        .purple,                // 13: Bright Magenta
        .cyan,                   // 14: Bright Cyan
        .white                   // 15: Bright White
    ]
}


extension TrueColor {
    var swiftUIColor: SwiftUI.Color? {
        return SwiftUI.Color(
            red: Double(red) / 255.0,
            green: Double(green) / 255.0,
            blue: Double(blue) / 255.0,
            opacity: 1.0
        )
    }
}
#endif
