import AppKit
import SwiftTUI

extension HStackControl: NSViewConvertible {
    func attributesDiffId() -> Int {
        var hasher = Hasher()
        alignment.hash(into: &hasher)
        spacing.hash(into: &hasher)
        return hasher.finalize()
    }
    
    func makeNSView(renderer: AppKitRenderer) -> NSView? {
        let stackView = HStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        stackView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        stackView.setContentHuggingPriority(.defaultLow, for: .vertical)
        stackView.orientation = .horizontal
        stackView.distribution = .gravityAreas
        
        return stackView
    }
    
    func updateView(_ view: NSView, renderer: AppKitRenderer) {
        guard let stackView = view as? HStackView else { return }

        stackView.alignment = NSLayoutConstraint.Attribute(alignment)
        stackView.spacing = CGFloat(spacing.intValue) * renderer.pixelBlockSize.width
        
        var offset = 0
        while offset < stackView.arrangedSubviews.count || offset < children.count {
            var subview =  offset < stackView.arrangedSubviews.count ? stackView.arrangedSubviews[offset] : nil
            var child = offset < children.count ? children[offset] : nil
            
            var subviewRemoved = false
            if let subview, subview.vNodeId != child?.vNodeId {
                stackView.removeArrangedSubview(subview)
                subview.removeFromSuperview()
                subviewRemoved = true
            }

            if let child, let childView = renderer.view(for: child), childView != subview || subviewRemoved {
                if offset < stackView.arrangedSubviews.count {
                    stackView.insertArrangedSubview(childView, at: offset)
                } else {
                    stackView.addArrangedSubview(childView)
                }

                if childView is NSStackView || childView is NSView {
                    let widthConstraint = childView.widthAnchor.constraint(lessThanOrEqualTo: stackView.widthAnchor)
                    widthConstraint.priority = .defaultLow
                    widthConstraint.isActive = true
                    let heightConstraint = childView.heightAnchor.constraint(equalTo: stackView.heightAnchor)
                    heightConstraint.priority = .defaultHigh
                    heightConstraint.isActive = true
                }
            }
            offset += 1
        }
    }
}

final private class HStackView: NSStackView {}
