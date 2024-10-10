import AppKit
import SwiftTUI

extension ColorControl: NSViewConvertible {
    func attributesDiffId() -> Int {
        color.hashValue
    }
    
    func makeNSView(renderer: AppKitRenderer) -> NSView? {
        let colorView = ColorView()
        colorView.translatesAutoresizingMaskIntoConstraints = false
        colorView.wantsLayer = true
        
        colorView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        colorView.setContentHuggingPriority(.defaultLow, for: .vertical)

        let widthConstraint = colorView.widthAnchor.constraint(greaterThanOrEqualToConstant: renderer.pixelBlockSize.width)
        widthConstraint.priority = .defaultLow
        widthConstraint.isActive = true
        
        let heightConstraint = colorView.heightAnchor.constraint(greaterThanOrEqualToConstant: renderer.pixelBlockSize.height)
        heightConstraint.priority = .defaultLow
        heightConstraint.isActive = true
        
        return colorView
    }
    
    func updateView(_ view: NSView, renderer: AppKitRenderer) {
        guard let colorView = view as? ColorView else { return }

        colorView.layer?.backgroundColor = NSColor(color)?.cgColor ?? NSColor.textColor.cgColor
    }
}

final private class ColorView: NSView {}
