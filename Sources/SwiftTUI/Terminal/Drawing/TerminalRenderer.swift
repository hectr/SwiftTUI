import Foundation

public class TerminalRenderer: Renderer {
    private var layer: Layer?

    /// Even though we only redraw invalidated parts of the screen, terminal
    /// drawing is currently still slow, as it involves moving the cursor
    /// position and printing a character there.
    /// This cache stores the screen content to see if printing is necessary.
    private var cache: [[Cell?]] = []

    /// The current cursor position, which might need to be updated before
    /// printing.
    private var currentPosition: Position = .zero

    /// Current text attributes
    private var currentForegroundColor: Color? = nil
    private var currentBackgroundColor: Color? = nil
    private var currentAttributes = CellAttributes()

    public weak var application: Application?

    public init() {}

    public func start(with layer: Layer) {
        setLayer(layer)
        setup()
    }

    private func setLayer(_ layer: Layer) {
        self.layer = layer
        self.updateWindowSize() // Set the initial size of the layer
        self.layer?.renderer = self
    }

    private func setup() {
        _write(EscapeSequence.enableAlternateBuffer)
        _write(EscapeSequence.clearScreen)
        _write(EscapeSequence.moveTo(currentPosition))
        _write(EscapeSequence.hideCursor)
    }

    /// Draw only the invalidated part of the layer.
    public func update() {
        if let invalidated = layer?.invalidated {
            draw(rect: invalidated)
            layer?.invalidated = nil
        }
    }

    public func stop() {
        _write(EscapeSequence.disableAlternateBuffer)
        _write(EscapeSequence.showCursor)
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
                _write(EscapeSequence.moveTo(position))
                self.currentPosition = position
            }
            if self.currentForegroundColor != cell.foregroundColor {
                _write(cell.foregroundColor.foregroundEscapeSequence)
                self.currentForegroundColor = cell.foregroundColor
            }
            let backgroundColor = cell.backgroundColor ?? .default
            if self.currentBackgroundColor != backgroundColor {
                _write(backgroundColor.backgroundEscapeSequence)
                self.currentBackgroundColor = backgroundColor
            }
            self.updateAttributes(cell.attributes)
            _write(String(cell.char))
            self.currentPosition.column += 1
        }
    }

    private func updateAttributes(_ attributes: CellAttributes) {
        if currentAttributes.bold != attributes.bold {
            if attributes.bold { _write(EscapeSequence.enableBold) }
            else { _write(EscapeSequence.disableBold) }
        }
        if currentAttributes.italic != attributes.italic {
            if attributes.italic { _write(EscapeSequence.enableItalic) }
            else { _write(EscapeSequence.disableItalic) }
        }
        if currentAttributes.underline != attributes.underline {
            if attributes.underline { _write(EscapeSequence.enableUnderline) }
            else { _write(EscapeSequence.disableUnderline) }
        }
        if currentAttributes.strikethrough != attributes.strikethrough {
            if attributes.strikethrough { _write(EscapeSequence.enableStrikethrough) }
            else { _write(EscapeSequence.disableStrikethrough) }
        }
        if currentAttributes.inverted != attributes.inverted {
            if attributes.inverted { _write(EscapeSequence.enableInverted) }
            else { _write(EscapeSequence.disableInverted) }
        }
        currentAttributes = attributes
    }

    private func _write(_ str: String) {
        str.withCString { _ = write(STDOUT_FILENO, $0, strlen($0)) }
    }

    private func updateWindowSize() {
        var size = winsize()
        guard ioctl(STDOUT_FILENO, UInt(TIOCGWINSZ), &size) == 0,
              size.ws_col > 0, size.ws_row > 0 else {
            assertionFailure("Could not get window size")
            return
        }
        if let layer {
            layer.frame.size = Size(width: Extended(Int(size.ws_col)), height: Extended(Int(size.ws_row)))
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
