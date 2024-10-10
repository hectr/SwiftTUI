import SwiftTUI

extension Control {
    /// Structural identity of the control.
    var vNodeId: String {
        var id = ""
        if let parent {
            id.append(parent.vNodeId)
            let index = parent.children.firstIndex(where: { control in
                control === self
            })
            if let index {
                id.append("[\(index)] → ")
            } else {
                id.append(" → ")
            }
        }
        id.append("\(type(of: self))")
        return id
    }

    /// Combines the control's and all of its children's structural identity with its attributes.
    func diffId() -> Int {
        var hasher = Hasher()
        hasher.combine(vNodeId)
        if let self = self as? NSViewConvertible {
            hasher.combine(self.attributesDiffId())
        }
        for child in children {
            hasher.combine(child.diffId())
        }
        return hasher.finalize()
    }
}
