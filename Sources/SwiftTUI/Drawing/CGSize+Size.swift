import Foundation

extension CGSize {
    init(_ size: Size) {
        self.init(
            width: CGFloat(size.width.intValue) * pixelBlockSize.width,
            height: CGFloat(size.height.intValue) * pixelBlockSize.height
        )
    }
}

extension Size {
    init(_ size: CGSize) {
        self.init(
            width: Extended(Int(size.width / pixelBlockSize.width)),
            height: Extended(Int(size.height / pixelBlockSize.height))
        )
    }
}
