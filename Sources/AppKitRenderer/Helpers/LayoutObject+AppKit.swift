import AppKit
import SwiftTUI

private var appKitViewAssociationKey: UInt8 = 0

extension LayoutObject {
    /// Weak reference to the `NSView` that renders the receiver.
    var appKitView: NSView? {
        set { objc_setAssociatedObject(self, &appKitViewAssociationKey, ViewWeakReference(newValue), .OBJC_ASSOCIATION_RETAIN) }
        get { (objc_getAssociatedObject(self, &appKitViewAssociationKey) as? ViewWeakReference)?.view }
    }
}

private final class ViewWeakReference {
    weak var view: NSView?

    init(_ view: NSView?) {
        self.view = view
    }
}
