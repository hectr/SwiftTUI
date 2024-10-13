import AppKit
import SwiftTUI

extension SpacerControl: NSViewConvertible {
    func attributesDiffId() -> Int {
        var hasher = Hasher()
        orientation.hash(into: &hasher)
        return hasher.finalize()
    }

    func makeNSView(renderer: AppKitRenderer) -> NSView? {
        let view = SpacerView()
        view.translatesAutoresizingMaskIntoConstraints = false
        
        view.setContentHuggingPriority(.defaultLow, for: .horizontal)
        view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        view.setContentHuggingPriority(.defaultLow, for: .vertical)
        view.setContentCompressionResistancePriority(.defaultLow, for: .vertical)

        return view
    }
    
    func updateView(_ view: NSView, renderer: AppKitRenderer) {}
}

final private class SpacerView: NSView {}
