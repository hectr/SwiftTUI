import AppKit

private var attributesHashValueAssociationKey: UInt8 = 0
private var controlIdAssociationKey: UInt8 = 0

extension NSView {
    /// Stores the `Control.diffId()` of the control rendered by this `NSView` for comparison and updating purposes.
    var controlDiffId: Int? {
        set { objc_setAssociatedObject(self, &attributesHashValueAssociationKey, newValue as? NSNumber, .OBJC_ASSOCIATION_RETAIN) }
        get { (objc_getAssociatedObject(self, &attributesHashValueAssociationKey) as? NSNumber)?.intValue }
    }
    
    /// Stores the `Control.vNodeId`, representing the structural identity of the control rendered by this `NSView`.
    var vNodeId: String? {
        set { objc_setAssociatedObject(self, &controlIdAssociationKey, newValue, .OBJC_ASSOCIATION_RETAIN) }
        get { objc_getAssociatedObject(self, &controlIdAssociationKey) as? String }
    }
}
