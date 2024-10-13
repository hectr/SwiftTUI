import AppKit
import SwiftTUI

extension DividerControl: NSViewConvertible {
    func attributesDiffId() -> Int {
        var hasher = Hasher()
        orientation.hash(into: &hasher)
        color.hash(into: &hasher)
        style.hash(into: &hasher)
        return hasher.finalize()
    }
    
    func makeNSView(renderer: AppKitRenderer) -> NSView? {
        let dividerView = DividerView()
        dividerView.translatesAutoresizingMaskIntoConstraints = false
        dividerView.wantsLayer = true
        
        dividerView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        dividerView.setContentHuggingPriority(.defaultLow, for: .vertical)
        
        return dividerView
    }
    
    func updateView(_ view: NSView, renderer: AppKitRenderer) {
        guard let dividerView = view as? DividerView else { return }

        // Update orientation and thickness
        let thickness = borderWidth(for: style)
        if orientation == .horizontal {
            NSLayoutConstraint.activate([
                dividerView.widthAnchor.constraint(equalToConstant: thickness),
            ])
        } else {
            NSLayoutConstraint.activate([
                dividerView.heightAnchor.constraint(equalToConstant: thickness),
            ])
        }
        
        // Update color
        dividerView.layer?.backgroundColor = NSColor(color)?.cgColor ?? NSColor.textColor.cgColor
    }
    
    private func borderWidth(for style: DividerStyle) -> CGFloat {
        switch style {
        case .default:
            return 1.0
        case .double:
            return 2.0
        case .heavy:
            return 3.0
        default:
            return 1.0
        }
    }
}

final private class DividerView: NSView {}
