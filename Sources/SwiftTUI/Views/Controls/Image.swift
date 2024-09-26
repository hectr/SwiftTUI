import Foundation

public enum ColorMode {
    case grayscale
    case color256
    case trueColor
}

/// A view that displays an image.
public struct Image: View, PrimitiveView {
    typealias PixelBlock = [[TrueColor]]
    typealias PixelBlockBitmap = UInt32

    static let pixelBlockSize = (width: 4, height: 8)
    
    private var pixels: PixelBlock
    private var colorMode: ColorMode

    /// Initialize an `Image` with a PPM image `path`.
    public init(path: String, colorMode: ColorMode = .color256) {
        self.init(
            try! PortablePixmapParser.parse(filePath: path),
            colorMode: colorMode
        )
    }

    /// Initialize an `Image` with a PPM image.
    public init(ppm data: Data, colorMode: ColorMode = .color256) {
        self.init(
            try! PortablePixmapParser.parse(data: data),
            colorMode: colorMode
        )
    }

    init(_ pixels: PixelBlock, colorMode: ColorMode) {
        self.pixels = pixels
        self.colorMode = colorMode
    }
    
    static var size: Int? { 1 }
    
    func buildNode(_ node: Node) {
        setupEnvironmentProperties(node: node)
        node.control = ImageControl(
            pixels: pixels,
            colorMode: colorMode
        )
    }
    
    func updateNode(_ node: Node) {
        setupEnvironmentProperties(node: node)
        node.view = self
        let control = node.control as! ImageControl
        control.pixels = pixels
        control.colorMode = colorMode
        control.layer.invalidate()
    }
    
    private class ImageControl: Control {
        var pixels: Image.PixelBlock
        var colorMode: ColorMode
        
        init(
            pixels: Image.PixelBlock,
            colorMode: ColorMode
        ) {
            self.pixels = pixels
            self.colorMode = colorMode
        }
        
        override func size(proposedSize: Size) -> Size {
            let imageHeight = pixels.count
            guard imageHeight > 0 else {
                return Size(width: 0, height: 0)
            }
            let imageWidth = pixels[0].count
            
            // Each terminal cell represents a pixel block
            let width = (imageWidth + pixelBlockSize.width - 1) / pixelBlockSize.width // ceiling ensures image size will fit all pixels
            let height = (imageHeight + pixelBlockSize.height - 1) / pixelBlockSize.height
            return Size(width: Extended(width), height: Extended(height))
        }
        
        override func cell(at position: Position) -> Cell? {
            guard !pixels.isEmpty else {
                return nil
            }
            
            let startY = position.line.intValue * pixelBlockSize.height
            let startX = position.column.intValue * pixelBlockSize.width
            let height = pixels.count
            let width = pixels[0].count
            
            if startY >= height || startX >= width {
                return nil
            }
            
            // Extract the block of pixels
            var block: Image.PixelBlock = []
            for y in startY..<min(startY + pixelBlockSize.height, height) {
                var row: [TrueColor] = []
                for x in startX..<min(startX + pixelBlockSize.width, width) {
                    row.append(pixels[y][x])
                }
                // Pad the row to ensure it has expected columns
                while row.count < pixelBlockSize.width {
                    let additionalColumn = row.last ?? TrueColor(red: 0, green: 0, blue: 0)
                    row.append(additionalColumn)
                }
                block.append(row)
            }
            
            // Pad the block to ensure it has expected rows
            while block.count < pixelBlockSize.height {
                let additionalRow = block.last ?? [TrueColor](repeating: TrueColor(red: 0, green: 0, blue: 0), count: pixelBlockSize.width)
                block.append(additionalRow)
            }

            return Cell.fromPixelBlock(block, colorMode: colorMode)
        }
    }
}
