import AppKit
import SwiftTUI

extension NSLayoutConstraint.Attribute {
    /// Initializes an `NSLayoutConstraint.Attribute` based on the given `VerticalAlignment`.
    init(_ verticalAlignment: VerticalAlignment) {
        switch verticalAlignment {
        case .top:
            self = .top
        case .center:
            self = .centerY
        case .bottom:
            self = .bottom
        }
    }
}
