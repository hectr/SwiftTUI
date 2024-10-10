import AppKit
import SwiftTUI

extension NSLayoutConstraint.Attribute {
    /// Initializes an `NSLayoutConstraint.Attribute` based on the given `HorizontalAlignment`.
    init(_ horizontalAlignment: HorizontalAlignment) {
        switch horizontalAlignment {
        case .leading:
            self = .left
        case .center:
            self = .centerX
        case .trailing:
            self = .right
        }
    }
}
