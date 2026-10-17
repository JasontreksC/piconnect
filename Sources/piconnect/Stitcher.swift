import CoreGraphics
import CoreImage
import Foundation
import ImageIO
import UniformTypeIdentifiers

enum Direction {
    case horizontal
    case vertical

    init?(argument: String) {
        switch argument.lowercased() {
        case "horizontal", "h", "가로":
            self = .horizontal
        case "vertical", "v", "세로":
            self = .vertical
        default:
            return nil
        }
    }

    var fileTag: String {
        switch self {
        case .horizontal: return "h"
        case .vertical: return "v"
        }
    }
}

enum PiconnectError: LocalizedError {
    case usage(String)
    case tooFewImages(Int)
    case unreadable(URL)
    case renderFailed
    case tooLarge
    case saveFailed(URL)

    var errorDescription: String? {
        switch self {
        case .usage(let message):
            return message
        case .tooFewImages(let count):
            return "이어붙이려면 이미지가 2개 이상 필요합니다. (인식된 이미지 \(count)개)"
        case .unreadable(let url):
            return "이미지를 열 수 없습니다: \(url.path)"
        case .renderFailed:
            return "이미지를 이어붙이지 못했습니다."
        case .tooLarge:
            return "이어붙인 결과가 너무 큽니다."
        case .saveFailed(let url):
            return "저장하지 못했습니다: \(url.path)"
        }
    }
}

enum ImageStitcher {
    static func isImageFile(_ url: URL) -> Bool {
        guard let type = UTType(filenameExtension: url.pathExtension) else { return false }
        return type.conforms(to: .image)
    }

    static func load(url: URL) throws -> CGImage {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else {
            throw PiconnectError.unreadable(url)
        }
        guard CGImageSourceGetCount(source) > 0 else {
            throw PiconnectError.unreadable(url)
        }

        let options = [kCGImageSourceShouldCacheImmediately: true] as CFDictionary
        guard let image = CGImageSourceCreateImageAtIndex(source, 0, options) else {
            throw PiconnectError.unreadable(url)
        }

        let orientation = orientation(of: source)
        if orientation == 1 {
            return image
        }
        return try oriented(image, orientation: orientation)
    }

    /// 가로면 높이를, 세로면 너비를 가장 큰 값에 맞춰 비율을 유지한 채 확대한다.
    static func stitch(_ images: [CGImage], direction: Direction) throws -> CGImage {
        guard images.count >= 2 else {
            throw PiconnectError.tooFewImages(images.count)
        }

        switch direction {
        case .horizontal:
            return try stitchHorizontally(images)
        case .vertical:
            return try stitchVertically(images)
        }
    }

    static func savePNG(_ image: CGImage, to url: URL) throws {
        let folder = url.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        guard let destination = CGImageDestinationCreateWithURL(
            url as CFURL,
            UTType.png.identifier as CFString,
            1,
            nil
        ) else {
            throw PiconnectError.saveFailed(url)
        }
        CGImageDestinationAddImage(destination, image, nil)
        guard CGImageDestinationFinalize(destination) else {
            throw PiconnectError.saveFailed(url)
        }
    }

    static func outputURL(near first: URL, direction: Direction) -> URL {
        let folder = first.deletingLastPathComponent()
        let tag = direction.fileTag
        var candidate = folder.appendingPathComponent("piconnect-\(tag).png")
        var index = 2
        let fileManager = FileManager.default
        while fileManager.fileExists(atPath: candidate.path) {
            candidate = folder.appendingPathComponent("piconnect-\(tag)-\(index).png")
            index += 1
        }
        return candidate
    }

    private static func stitchHorizontally(_ images: [CGImage]) throws -> CGImage {
        let targetHeight = images.map(\.height).max() ?? 0
        guard targetHeight > 0 else { throw PiconnectError.renderFailed }

        var placed: [(image: CGImage, width: Int)] = []
        var totalWidth = 0
        for image in images {
            guard image.width > 0, image.height > 0 else { throw PiconnectError.renderFailed }
            let width = scaledLength(image.width, image.height, target: targetHeight)
            totalWidth = try adding(totalWidth, width)
            placed.append((image, width))
        }

        let context = try makeContext(width: totalWidth, height: targetHeight)
        var x = 0
        for item in placed {
            context.draw(
                item.image,
                in: CGRect(x: x, y: 0, width: item.width, height: targetHeight)
            )
            x += item.width
        }
        guard let result = context.makeImage() else { throw PiconnectError.renderFailed }
        return result
    }

    private static func stitchVertically(_ images: [CGImage]) throws -> CGImage {
        let targetWidth = images.map(\.width).max() ?? 0
        guard targetWidth > 0 else { throw PiconnectError.renderFailed }

        var placed: [(image: CGImage, height: Int)] = []
        var totalHeight = 0
        for image in images {
            guard image.width > 0, image.height > 0 else { throw PiconnectError.renderFailed }
            let height = scaledLength(image.height, image.width, target: targetWidth)
            totalHeight = try adding(totalHeight, height)
            placed.append((image, height))
        }

        let context = try makeContext(width: targetWidth, height: totalHeight)
        // Core Graphics 원점은 왼쪽 아래. 첫 이미지가 위에 오도록 위에서부터 쌓는다.
        var y = totalHeight
        for item in placed {
            y -= item.height
            context.draw(
                item.image,
                in: CGRect(x: 0, y: y, width: targetWidth, height: item.height)
            )
        }
        guard let result = context.makeImage() else { throw PiconnectError.renderFailed }
        return result
    }

    /// `source` 축 길이를 `target`에 맞출 때 `length` 축이 얼마나 되는지. 이미 같으면 확대하지 않는다.
    private static func scaledLength(_ length: Int, _ source: Int, target: Int) -> Int {
        if source == target { return length }
        return max(1, Int((Double(length) * Double(target) / Double(source)).rounded()))
    }

    private static func adding(_ lhs: Int, _ rhs: Int) throws -> Int {
        let (sum, overflow) = lhs.addingReportingOverflow(rhs)
        if overflow { throw PiconnectError.tooLarge }
        return sum
    }

    private static func makeContext(width: Int, height: Int) throws -> CGContext {
        guard width > 0, height > 0 else { throw PiconnectError.renderFailed }
        guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) else {
            throw PiconnectError.renderFailed
        }
        let alpha = CGImageAlphaInfo.premultipliedLast.rawValue
        let bitmapInfo = CGBitmapInfo.byteOrder32Big.rawValue | alpha
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: bitmapInfo
        ) else {
            throw PiconnectError.tooLarge
        }
        context.interpolationQuality = .high
        return context
    }

    private static func orientation(of source: CGImageSource) -> Int32 {
        guard let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any] else {
            return 1
        }
        if let value = properties[kCGImagePropertyOrientation] as? Int {
            return Int32(value)
        }
        return 1
    }

    private static func oriented(_ image: CGImage, orientation: Int32) throws -> CGImage {
        let input = CIImage(cgImage: image).oriented(forExifOrientation: orientation)
        let context = CIContext(options: [.workingColorSpace: NSNull()])
        guard let result = context.createCGImage(input, from: input.extent.integral) else {
            throw PiconnectError.renderFailed
        }
        return result
    }
}
