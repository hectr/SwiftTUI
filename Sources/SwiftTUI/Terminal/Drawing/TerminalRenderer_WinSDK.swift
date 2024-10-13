#if canImport(WinSDK)

import Foundation
import WinSDK

public class TerminalRenderer: Renderer {
    private var layer: Layer?

    /// Cache for screen content to optimize drawing
    private var cache: [[Cell?]] = []

    /// Current cursor position
    private var currentPosition: Position = .zero

    /// Current text attributes
    private var currentForegroundColor: Color? = nil
    private var currentBackgroundColor: Color? = nil
    private var currentAttributes = CellAttributes()

    public weak var application: Application?

    /// Handle to the console output
    private var hConsole: HANDLE?

    /// Original console mode (for restoring later)
    private var originalConsoleMode: DWORD = 0

    public init() {}

    public func start(with layer: Layer) {
        self.layer = layer
        self.layer?.renderer = self
        setup()
    }

    private func setup() {
        // Get handle to console output
        hConsole = GetStdHandle(STD_OUTPUT_HANDLE)
        guard hConsole != INVALID_HANDLE_VALUE else {
            fatalError("Unable to get console handle")
        }

        // Enable ANSI escape sequences if supported
        enableVirtualTerminalProcessing()

        // Clear screen and hide cursor
        _write(EscapeSequence.clearScreen)
        _write(EscapeSequence.hideCursor)

        // Initialize window size and cache
        updateWindowSize()

        moveCursor(to: Position(column: 0, line: 0)) // Move cursor to home position
    }

    public func update() {
        if let invalidated = layer?.invalidated {
            draw(rect: invalidated)
            layer?.invalidated = nil
        }
    }

    public func stop() {
        _write(EscapeSequence.resetAttributes)
        _write(EscapeSequence.clearScreen)
        _write(EscapeSequence.disableAlternateBuffer)
        _write(EscapeSequence.showCursor)

        // Reset console mode
        if let hConsole = hConsole {
            SetConsoleMode(hConsole, originalConsoleMode)
        }
    }

    public func handleWindowSizeChange() {
        updateWindowSize()
        layer?.invalidate()
        application?.control.layout(size: layer?.frame.size ?? .zero) // Update control layout
        update()
    }

    private func draw(rect: Rect? = nil) {
        guard let layer else {
            assertionFailure("Attempting to draw before layer is set")
            return
        }
        let rect = rect ?? Rect(position: .zero, size: layer.frame.size)
        guard rect.size.width > 0, rect.size.height > 0 else { return }
        for line in rect.minLine.intValue ... rect.maxLine.intValue {
            for column in rect.minColumn.intValue ... rect.maxColumn.intValue {
                let position = Position(column: Extended(column), line: Extended(line))
                if let cell = layer.cell(at: position) {
                    drawPixel(cell, at: position)
                }
            }
        }
    }

    private func drawPixel(_ cell: Cell, at position: Position) {
        guard let layer,
              position.column >= 0, position.line >= 0,
              position.column < layer.frame.size.width, position.line < layer.frame.size.height else {
            return
        }
        if cache[position.line.intValue][position.column.intValue] != cell {
            cache[position.line.intValue][position.column.intValue] = cell
            if self.currentPosition != position {
                moveCursor(to: position)
                self.currentPosition = position
            }
            updateAttributes(for: cell)
            _write(String(cell.char))
            self.currentPosition.column += 1
        }
    }

    private func moveCursor(to position: Position) {
        _write(EscapeSequence.moveTo(position))
    }

    private func updateAttributes(for cell: Cell) {
        // Handle foreground color
        if self.currentForegroundColor != cell.foregroundColor {
            _write(cell.foregroundColor.foregroundEscapeSequence)
            self.currentForegroundColor = cell.foregroundColor
        }
        // Handle background color
        let backgroundColor = cell.backgroundColor ?? .default
        if self.currentBackgroundColor != backgroundColor {
            _write(backgroundColor.backgroundEscapeSequence)
            self.currentBackgroundColor = backgroundColor
        }
        // Handle text attributes individually
        let attributes = cell.attributes
        
        if currentAttributes.bold != attributes.bold {
            _write(attributes.bold ? EscapeSequence.enableBold : EscapeSequence.disableBold)
        }
        if currentAttributes.italic != attributes.italic {
            _write(attributes.italic ? EscapeSequence.enableItalic : EscapeSequence.disableItalic)
        }
        if currentAttributes.underline != attributes.underline {
            _write(attributes.underline ? EscapeSequence.enableUnderline : EscapeSequence.disableUnderline)
        }
        if currentAttributes.strikethrough != attributes.strikethrough {
            _write(attributes.strikethrough ? EscapeSequence.enableStrikethrough : EscapeSequence.disableStrikethrough)
        }
        if currentAttributes.inverted != attributes.inverted {
            _write(attributes.inverted ? EscapeSequence.enableInverted : EscapeSequence.disableInverted)
        }

        // Update the current attributes
        currentAttributes = attributes
    }

    private func _write(_ str: String) {
        guard let hConsole = hConsole else { return }
        let utf16Str = str.utf16
        var charsWritten: DWORD = 0
        WriteConsoleW(hConsole, Array(utf16Str), DWORD(utf16Str.count), &charsWritten, nil)
    }

    private func updateWindowSize() {
        guard let hConsole = hConsole else { return }
        var csbi = CONSOLE_SCREEN_BUFFER_INFO()
        GetConsoleScreenBufferInfo(hConsole, &csbi)
        let width = Int(csbi.srWindow.Right - csbi.srWindow.Left + 1)
        let height = Int(csbi.srWindow.Bottom - csbi.srWindow.Top + 1)
        if let layer {
            layer.frame.size = Size(width: Extended(width), height: Extended(height))
            setCache(for: layer)
        }
    }

    private func setCache(for layer: Layer) {
        cache = .init(
            repeating: .init(repeating: nil, count: layer.frame.size.width.intValue),
            count: layer.frame.size.height.intValue
        )
    }

    private func enableVirtualTerminalProcessing() {
        guard let hConsole = hConsole else { return }
        var mode: DWORD = 0
        GetConsoleMode(hConsole, &mode)
        originalConsoleMode = mode
        mode |= DWORD(ENABLE_VIRTUAL_TERMINAL_PROCESSING)
        SetConsoleMode(hConsole, mode)
    }
}

#endif
