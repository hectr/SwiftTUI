import AppKit
import SwiftTUI

extension ZStackControl: NSViewConvertible {
    func attributesDiffId() -> Int {
        var hasher = Hasher()
        alignment.hash(into: &hasher)
        return hasher.finalize()
    }
    
    func makeNSView(renderer: AppKitRenderer) -> NSView? {
        let containerView = ZStackView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        containerView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        containerView.setContentHuggingPriority(.defaultLow, for: .vertical)

        return containerView
    }
    
    func updateView(_ view: NSView, renderer: AppKitRenderer) {
        guard let containerView = view as? ZStackView else { return }

        var offset = 0
        while offset < containerView.subviews.count || offset < children.count {
            var subview =  offset < containerView.subviews.count ? containerView.subviews[offset] : nil
            var child = offset < children.count ? children[offset] : nil

            var subviewRemoved = false
            if let subview, subview.vNodeId != child?.vNodeId {
                subview.removeFromSuperview()
                subviewRemoved = true
            }

            if let child, let childView = renderer.view(for: child), childView != subview || subviewRemoved {
                containerView.addSubview(childView)
                alignChildView(childView, in: containerView)
            }
            offset += 1
        }
    }
    
    private func alignChildView(_ childView: NSView, in containerView: NSView) {
        var constraints: [NSLayoutConstraint] = []
        
        switch alignment.horizontalAlignment {
        case .leading:
            constraints.append(childView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor))
        case .center:
            constraints.append(childView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor))
        case .trailing:
            constraints.append(childView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor))
        }
        
        switch alignment.verticalAlignment {
        case .top:
            constraints.append(childView.topAnchor.constraint(equalTo: containerView.topAnchor))
        case .center:
            constraints.append(childView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor))
        case .bottom:
            constraints.append(childView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor))
        }
        
        NSLayoutConstraint.activate(constraints)
    }
}

final private class ZStackView: NSView {}
