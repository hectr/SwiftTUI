import Foundation

class MouseEventParser {
    struct MouseEvent {
        enum EventType {
            case press
            case release
            case wheel
            case move
        }

        let eventType: EventType
        let button: Int
        let column: Int
        let row: Int
    }
    
    enum ParserState {
        case none
        case esc
        case csi
        case parameters(String)
    }

    var state: ParserState = .none
    var mouseEvent: MouseEvent?

    func parse(character: Character) -> Bool {
        switch state {
        case .none:
            if character == ASCII.ESC {
                state = .esc
                return true
            }
            return false
        case .esc:
            if character == "[" {
                state = .csi
                return true
            } else {
                state = .none
                return false
            }
        case .csi:
            if character == "M" || character == "<" {
                state = .parameters("")
                return true
            } else {
                state = .none
                return false
            }
        case .parameters(let params):
            if character.isNumber || character == ";" || character == "m" || character == "M" || character == "<" || character == "-" {
                let newParams = params + String(character)
                if character == "M" || character == "m" {
                    // End of mouse event sequence
                    parseMouseEvent(parameters: newParams)
                    state = .none
                    return true
                } else {
                    state = .parameters(newParams)
                    return true
                }
            } else {
                state = .none
                return false
            }
        }
    }

    private func parseMouseEvent(parameters: String) {
        // Example parameters: "<0;15;10M" or "<35;15;10m"
        let cleanedParams = parameters.trimmingCharacters(in: CharacterSet(charactersIn: "<>"))
        let components = cleanedParams.components(separatedBy: [";", "M", "m"]).filter { !$0.isEmpty }

        if components.count >= 3,
           let cb = Int(components[0]),
           let x = Int(components[1]),
           let y = Int(components[2]) {
            let eventType: MouseEvent.EventType = (parameters.last == "M") ? .press : .release
            mouseEvent = MouseEvent(eventType: eventType, button: cb, column: x, row: y)
        }
    }
}

