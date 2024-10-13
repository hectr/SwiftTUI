import Foundation

public class TerminalInputHandler: InputHandler {
    public weak var application: Application?

    private var stdInSource: DispatchSourceRead?
    private var sigWinChSource: DispatchSourceSignal?
    private var sigIntSource: DispatchSourceSignal?

    private var arrowKeyParser = ArrowKeyParser()
    private var mouseEventParser = MouseEventParser()

    public init() {}

    public func start() {
        setInputMode()
        enableMouseTracking()
        setupInputHandlers()
    }

    public func stop() {
        disableMouseTracking()
        resetInputMode() // Fix for: https://github.com/rensbreur/SwiftTUI/issues/25
        stdInSource?.cancel()
        sigWinChSource?.cancel()
        sigIntSource?.cancel()
    }

    private func setInputMode() {
        var tattr = termios()
        tcgetattr(STDIN_FILENO, &tattr)
        tattr.c_lflag &= ~tcflag_t(ECHO | ICANON | ICRNL)
        tcsetattr(STDIN_FILENO, TCSAFLUSH, &tattr)
    }

    /// Fix for: https://github.com/rensbreur/SwiftTUI/issues/25
    private func resetInputMode() {
        // Reset ECHO and ICANON values:
        var tattr = termios()
        tcgetattr(STDIN_FILENO, &tattr)
        tattr.c_lflag |= tcflag_t(ECHO | ICANON)
        tcsetattr(STDIN_FILENO, TCSAFLUSH, &tattr)
    }

    private func enableMouseTracking() {
        _write(EscapeSequence.enableBasicMouseTracking)
        _write(EscapeSequence.enableButtonCellMouseTracking)
        _write(EscapeSequence.enableSGRExtendedMouseMode)
    }

    private func disableMouseTracking() {
        _write(EscapeSequence.disableBasicMouseTracking)
        _write(EscapeSequence.disableButtonCellMouseTracking)
        _write(EscapeSequence.disableSGRExtendedMouseMode)
    }

    private func setupInputHandlers() {
        let stdInSource = DispatchSource.makeReadSource(fileDescriptor: STDIN_FILENO, queue: .main)
        stdInSource.setEventHandler(qos: .default, flags: [], handler: handleInput)
        stdInSource.resume()
        self.stdInSource = stdInSource

        let sigWinChSource = DispatchSource.makeSignalSource(signal: SIGWINCH, queue: .main)
        sigWinChSource.setEventHandler(qos: .default, flags: [], handler: handleWindowSizeChange)
        sigWinChSource.resume()
        self.sigWinChSource = sigWinChSource

        signal(SIGINT, SIG_IGN)
        let sigIntSource = DispatchSource.makeSignalSource(signal: SIGINT, queue: .main)
        sigIntSource.setEventHandler(qos: .default, flags: [], handler: handleInterrupt)
        sigIntSource.resume()
        self.sigIntSource = sigIntSource
    }

    private func handleInput() {
        let data = FileHandle.standardInput.availableData

        guard let string = String(data: data, encoding: .utf8) else {
            return
        }

        guard let application = application else { return }
        let window = application.window

        var index: String.Index
        var parsingIndex = string.startIndex
        parsingLoop:
        while parsingIndex < string.endIndex {
            // Attempt to parse mouse event:
            index = parsingIndex
            mouseLoop:
            while index < string.endIndex {
                let char = string[index]
                index = string.index(after: index)

                guard mouseEventParser.parse(character: char) else {
                    // Cancel mouse event parsing.
                    break mouseLoop
                }

                guard let event = mouseEventParser.mouseEvent else {
                    // Continue parsing mouse event...
                    continue mouseLoop
                }

                // Handle mouse event.
                mouseEventParser.mouseEvent = nil
                handleMouseEvent(event)
                parsingIndex = index
                continue parsingLoop
            }

            // Mouse event not identified; attempt to parse arrow key:
            index = parsingIndex
            arrowLoop:
            while index < string.endIndex {
                let char = string[index]
                index = string.index(after: index)

                guard arrowKeyParser.parse(character: char) else {
                    // Cancel arrow key parsing.
                    break arrowLoop
                }

                guard let key = arrowKeyParser.arrowKey else {
                    // Continue parsing arrow key...
                    continue arrowLoop
                }

                // Handle arrow key.
                arrowKeyParser.arrowKey = nil
                handleArrowKey(key)
                parsingIndex = index
                continue parsingLoop
            }

            // Arrow key not identified; handle as key press:
            let char = string[parsingIndex]
            parsingIndex = string.index(after: parsingIndex)

            if char == ASCII.EOT {
                // Handle EOT
                application.stop()

            } else {
                // Handle regular character input
                window.firstResponder?.handleEvent(char)
            }
        }
    }

    private func handleWindowSizeChange() {
        application?.handleWindowSizeChange()
    }

    private func handleArrowKey(_ key: ArrowKeyParser.ArrowKey) {
        guard let application = application else { return }
        let window = application.window

        if key == .down {
            if let next = window.firstResponder?.selectableElement(below: 0) {
                window.firstResponder?.resignFirstResponder()
                window.firstResponder = next
                window.firstResponder?.becomeFirstResponder()
            }
        } else if key == .up {
            if let next = window.firstResponder?.selectableElement(above: 0) {
                window.firstResponder?.resignFirstResponder()
                window.firstResponder = next
                window.firstResponder?.becomeFirstResponder()
            }
        } else if key == .right {
            if let next = window.firstResponder?.selectableElement(rightOf: 0) {
                window.firstResponder?.resignFirstResponder()
                window.firstResponder = next
                window.firstResponder?.becomeFirstResponder()
            }
        } else if key == .left {
            if let next = window.firstResponder?.selectableElement(leftOf: 0) {
                window.firstResponder?.resignFirstResponder()
                window.firstResponder = next
                window.firstResponder?.becomeFirstResponder()
            }
        }
    }

    private func handleMouseEvent(_ event: MouseEventParser.MouseEvent) {
        guard let application = application else { return }
        let window = application.window

        // Convert terminal coordinates to application coordinates
        let position = Position(column: Extended(event.column - 1), line: Extended(event.row - 1))

        // Dispatch the event to the control at the position
        if let control = application.control.selectableElement(at: position) {
            window.firstResponder?.resignFirstResponder()
            window.firstResponder = control
            window.firstResponder?.becomeFirstResponder()

            if event.eventType == .release , let buttonControl = control as? ButtonControl {
                buttonControl.handleEvent("\n")
            }
        }
    }

    private func handleInterrupt() {
        application?.stop()
    }

    private func _write(_ str: String) {
        str.withCString { _ = write(STDOUT_FILENO, $0, strlen($0)) }
    }
}
