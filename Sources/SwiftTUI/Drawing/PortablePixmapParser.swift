import Foundation

enum PortablePixmapParser {
    enum Failure: Error {
        case failedToReadFile
        case unsupportedPPMFormat
        case invalidDimensions
        case invalidMaxColorValue
        case notEnoughPixelData
    }
    
    enum MagicNumber: String {
        case P3 // ascii
        case P6 // raw
    }
    
    static func parse(filePath: String) throws -> Image.PixelBlock {
        let fileData = try Data(contentsOf: URL(fileURLWithPath: filePath))
        return try parse(data: fileData)
    }
    
    static func parse(data: Data) throws -> Image.PixelBlock {
        var offset = 0
        let bytes = [UInt8](data)
        
        // Helper function to skip whitespace and comments
        func nextToken() throws -> String {
            var token = ""
            while offset < bytes.count {
                let byte = bytes[offset]
                if byte == UInt8(ascii: "#") {
                    // Skip the comment line
                    while offset < bytes.count && bytes[offset] != UInt8(ascii: "\n") {
                        offset += 1
                    }
                } else if byte.isWhitespaceOrNewline() {
                    offset += 1
                } else {
                    // Start of a token
                    while offset < bytes.count && !bytes[offset].isWhitespaceOrNewline() && bytes[offset] != UInt8(ascii: "#") {
                        token.append(Character(UnicodeScalar(bytes[offset])))
                        offset += 1
                    }
                    break
                }
            }
            if token.isEmpty {
                throw Failure.unsupportedPPMFormat
            }
            return token
        }
        
        // Read magic number
        let magicNumberStr = try nextToken()
        guard let magicNumber = MagicNumber(rawValue: magicNumberStr) else {
            throw Failure.unsupportedPPMFormat
        }
        
        // Read width
        let widthStr = try nextToken()
        guard let width = Int(widthStr), width > 0 else {
            throw Failure.invalidDimensions
        }
        
        // Read height
        let heightStr = try nextToken()
        guard let height = Int(heightStr), height > 0 else {
            throw Failure.invalidDimensions
        }
        
        // Read max color value
        let maxColorValueStr = try nextToken()
        guard let maxColorValue = Int(maxColorValueStr), maxColorValue > 0 && maxColorValue <= 65535 else {
            throw Failure.invalidMaxColorValue
        }
        
        // Determine if maxColorValue is greater than 255 (for P6 binary with 16-bit color)
        let isTwoBytesPerColor = maxColorValue > 255
        
        // Calculate the number of pixels
        let expectedPixelCount = width * height
        
        switch magicNumber {
        case .P3:
            // ASCII PPM
            // Read remaining data as a string
            guard let remainingString = String(data: data.subdata(in: offset..<data.count), encoding: .ascii) else {
                throw Failure.notEnoughPixelData
            }
            let scanner = Scanner(string: remainingString)
            scanner.charactersToBeSkipped = CharacterSet.whitespacesAndNewlines
            
            var pixels: Image.PixelBlock = []
            for _ in 0..<height {
                var row: [TrueColor] = []
                for _ in 0..<width {
                    var r = 0, g = 0, b = 0
                    if !scanner.scanInt(&r) || !scanner.scanInt(&g) || !scanner.scanInt(&b) {
                        throw Failure.notEnoughPixelData
                    }
                    row.append(TrueColor(red: r, green: g, blue: b))
                }
                pixels.append(row)
            }
            return pixels
            
        case .P6:
            // Binary PPM
            // After the header, there should be one whitespace character before pixel data
            // Ensure that the next byte is a whitespace
            if offset < bytes.count {
                let byte = bytes[offset]
                if !byte.isWhitespaceOrNewline() {
                    throw Failure.unsupportedPPMFormat
                }
                offset += 1 // Skip the whitespace
            }
            
            // Calculate expected data size
            let bytesPerColor = isTwoBytesPerColor ? 2 : 1
            let expectedDataSize = expectedPixelCount * 3 * bytesPerColor
            
            guard offset + expectedDataSize <= bytes.count else {
                throw Failure.notEnoughPixelData
            }
            
            var pixels: Image.PixelBlock = []
            for _ in 0..<height {
                var row: [TrueColor] = []
                for _ in 0..<width {
                    var r = 0, g = 0, b = 0
                    if isTwoBytesPerColor {
                        // Big endian two bytes per color
                        r = (Int(bytes[offset]) << 8) | Int(bytes[offset + 1])
                        g = (Int(bytes[offset + 2]) << 8) | Int(bytes[offset + 3])
                        b = (Int(bytes[offset + 4]) << 8) | Int(bytes[offset + 5])
                        offset += 6
                    } else {
                        r = Int(bytes[offset])
                        g = Int(bytes[offset + 1])
                        b = Int(bytes[offset + 2])
                        offset += 3
                    }
                    // Normalize colors to 0-255 if maxColorValue > 255
                    if maxColorValue > 255 {
                        r = r * 255 / maxColorValue
                        g = g * 255 / maxColorValue
                        b = b * 255 / maxColorValue
                    }
                    row.append(TrueColor(red: r, green: g, blue: b))
                }
                pixels.append(row)
            }
            return pixels
        }
    }
}

extension UInt8 {
    fileprivate func isWhitespaceOrNewline() -> Bool {
        CharacterSet.whitespacesAndNewlines.contains(UnicodeScalar(self))
    }
}
