#if canImport(WinSDK)

import Foundation
import WinSDK

public class TerminalInputHandler: InputHandler {
    public weak var application: Application?

    private var inputThread: Thread?
    private var isRunning = false

    private var originalConsoleMode: DWORD = 0

    public init() {}

    public func start() {
        setInputMode()
        isRunning = true
        inputThread = Thread(block: self.inputLoop)
        inputThread?.start()
    }

    public func stop() {
        isRunning = false
        resetInputMode()
        inputThread?.cancel()
        inputThread = nil
    }

    private func setInputMode() {
        let hStdin = GetStdHandle(STD_INPUT_HANDLE)
        guard hStdin != INVALID_HANDLE_VALUE else {
            fatalError("Unable to get console input handle")
        }

        var mode: DWORD = 0
        if GetConsoleMode(hStdin, &mode) == false {
            fatalError("Unable to get console mode")
        }
        originalConsoleMode = mode

        // Disable echo input and processed input
        mode &= ~DWORD(ENABLE_ECHO_INPUT | ENABLE_PROCESSED_INPUT)
        // Enable extended flags
        mode |= DWORD(ENABLE_EXTENDED_FLAGS)
        if SetConsoleMode(hStdin, mode) == false {
            fatalError("Unable to set console mode")
        }
    }

    private func resetInputMode() {
        let hStdin = GetStdHandle(STD_INPUT_HANDLE)
        guard hStdin != INVALID_HANDLE_VALUE else {
            return
        }
        SetConsoleMode(hStdin, originalConsoleMode)
    }

    private func inputLoop() {
        let hStdin = GetStdHandle(STD_INPUT_HANDLE)
        guard hStdin != INVALID_HANDLE_VALUE else {
            fatalError("Unable to get console input handle")
        }

        var record = INPUT_RECORD()
        var eventsRead: DWORD = 0

        while isRunning && !Thread.current.isCancelled {
            if ReadConsoleInputW(hStdin, &record, 1, &eventsRead) == false {
                continue
            }

            if eventsRead == 0 {
                continue
            }

            switch record.EventType {
            case WORD(KEY_EVENT):
                handleKeyEvent(record.Event.KeyEvent)

            case WORD(WINDOW_BUFFER_SIZE_EVENT):
                DispatchQueue.main.async {
                    self.handleWindowSizeChange()
                }
            
            default:
                break
            }
        }
    }

    private func handleKeyEvent(_ keyEvent: KEY_EVENT_RECORD) {
        guard keyEvent.bKeyDown != false else { return }

        let virtualKeyCode = keyEvent.wVirtualKeyCode
        let unicodeChar = keyEvent.uChar.UnicodeChar

        let ctrlPressed = keyEvent.dwControlKeyState & (DWORD(LEFT_CTRL_PRESSED) | DWORD(RIGHT_CTRL_PRESSED)) != 0

        // Handle Ctrl+C (interrupt)
        if ctrlPressed && (unicodeChar == 0x03 || unicodeChar == 0x63 || unicodeChar == 0x43) {
            handleInterrupt()
            return
        }

        // Handle arrow keys and other special keys
        switch virtualKeyCode {
        case WORD(VK_LEFT):
            DispatchQueue.main.async {
                self.handleArrowKey(.left)
            }
        case WORD(VK_RIGHT):
            DispatchQueue.main.async {
                self.handleArrowKey(.right)
            }
        case WORD(VK_UP):
            DispatchQueue.main.async {
                self.handleArrowKey(.up)
            }
        case WORD(VK_DOWN):
            DispatchQueue.main.async {
                self.handleArrowKey(.down)
            }
        case WORD(VK_RETURN):
            DispatchQueue.main.async {
                self.application?.window.firstResponder?.handleEvent("\n")
            }
        case WORD(VK_BACK):
            DispatchQueue.main.async {
                self.application?.window.firstResponder?.handleEvent(ASCII.DEL)
            }
        default:
            // Handle regular character input
            if unicodeChar != 0 {
                let scalarValue = UInt32(unicodeChar)
                if let scalar = UnicodeScalar(scalarValue) {
                    let char = Character(scalar)
                    DispatchQueue.main.async {
                        self.application?.window.firstResponder?.handleEvent(char)
                    }
                }
            }
        }
    }

    private func handleArrowKey(_ key: ArrowKeyParser.ArrowKey) {
        guard let application = application else { return }
        let window = application.window

        switch key {
        case .down:
            if let next = window.firstResponder?.selectableElement(below: 0) {
                window.firstResponder?.resignFirstResponder()
                window.firstResponder = next
                window.firstResponder?.becomeFirstResponder()
            }
        case .up:
            if let next = window.firstResponder?.selectableElement(above: 0) {
                window.firstResponder?.resignFirstResponder()
                window.firstResponder = next
                window.firstResponder?.becomeFirstResponder()
            }
        case .right:
            if let next = window.firstResponder?.selectableElement(rightOf: 0) {
                window.firstResponder?.resignFirstResponder()
                window.firstResponder = next
                window.firstResponder?.becomeFirstResponder()
            }
        case .left:
            if let next = window.firstResponder?.selectableElement(leftOf: 0) {
                window.firstResponder?.resignFirstResponder()
                window.firstResponder = next
                window.firstResponder?.becomeFirstResponder()
            }
        }
    }

    private func handleWindowSizeChange() {
        application?.renderer.handleWindowSizeChange()
    }

    private func handleInterrupt() {
        DispatchQueue.main.async {
            self.application?.stop()
        }
    }
}

#endif
