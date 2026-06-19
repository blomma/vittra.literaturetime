import AppKit
import Foundation

enum ScreenshotProcessingError: Error, CustomStringConvertible {
    case invalidImage(URL)
    case bitmapCreationFailed
    case pngEncodingFailed
    case unknownScreen(String)

    var description: String {
        switch self {
        case .invalidImage(let url): "Could not load screenshot at \(url.path)"
        case .bitmapCreationFailed: "Could not create the output bitmap"
        case .pngEncodingFailed: "Could not encode the output as PNG"
        case .unknownScreen(let name): "No caption is configured for \(name)"
        }
    }
}

struct ScreenshotProcessor {
    func process(
        input: URL,
        output: URL,
        device: ScreenshotPlan.Device,
        screenName: String
    ) throws {
        guard let source = NSImage(contentsOf: input),
              let sourceCGImage = source.cgImage(forProposedRect: nil, context: nil, hints: nil)
        else {
            throw ScreenshotProcessingError.invalidImage(input)
        }

        guard let screen = ScreenshotPlan.screens.first(where: { $0.name == screenName }) else {
            throw ScreenshotProcessingError.unknownScreen(screenName)
        }

        let size = device.screenshotSize
        guard let bitmap = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: Int(size.width),
            pixelsHigh: Int(size.height),
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        ), let context = NSGraphicsContext(bitmapImageRep: bitmap) else {
            throw ScreenshotProcessingError.bitmapCreationFailed
        }

        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = context
        defer { NSGraphicsContext.restoreGraphicsState() }

        let canvas = CGRect(origin: .zero, size: size)
        let gradient = NSGradient(colors: [
            NSColor(red: 0.141, green: 0.141, blue: 0.196, alpha: 1), // #242432
            NSColor(red: 0.220, green: 0.192, blue: 0.212, alpha: 1), // #383136
        ])!
        gradient.draw(in: canvas, angle: 90)

        let captionHeight = size.height * 0.19
        CaptionOverlay(text: screen.caption).draw(
            in: CGRect(x: 0, y: size.height - captionHeight, width: size.width, height: captionHeight)
        )

        let available = CGRect(
            x: size.width * 0.075,
            y: size.height * 0.045,
            width: size.width * 0.85,
            height: size.height - captionHeight - size.height * 0.065
        )
        let sourceAspect = CGFloat(sourceCGImage.width) / CGFloat(sourceCGImage.height)
        let availableAspect = available.width / available.height
        let imageSize: CGSize
        if sourceAspect > availableAspect {
            imageSize = CGSize(width: available.width, height: available.width / sourceAspect)
        } else {
            imageSize = CGSize(width: available.height * sourceAspect, height: available.height)
        }

        let deviceRect = CGRect(
            x: available.midX - imageSize.width / 2,
            y: available.midY - imageSize.height / 2,
            width: imageSize.width,
            height: imageSize.height
        )
        let bezel = max(12, min(deviceRect.width, deviceRect.height) * 0.018)
        let outerRect = deviceRect.insetBy(dx: -bezel, dy: -bezel)
        let radius = min(outerRect.width, outerRect.height) * 0.045

        NSColor.black.setFill()
        NSBezierPath(roundedRect: outerRect, xRadius: radius, yRadius: radius).fill()

        let clippingPath = NSBezierPath(
            roundedRect: deviceRect,
            xRadius: max(4, radius - bezel),
            yRadius: max(4, radius - bezel)
        )
        clippingPath.addClip()
        context.cgContext.interpolationQuality = .high
        context.cgContext.draw(sourceCGImage, in: deviceRect)

        try FileManager.default.createDirectory(
            at: output.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        guard let png = bitmap.representation(using: .png, properties: [:]) else {
            throw ScreenshotProcessingError.pngEncodingFailed
        }
        try png.write(to: output, options: .atomic)
    }
}

@main
enum ScreenshotProcessorCommand {
    static func main() throws {
        let arguments = CommandLine.arguments
        guard arguments.count == 5,
              let device = ScreenshotPlan.Device(rawValue: arguments[3])
        else {
            FileHandle.standardError.write(
                Data("Usage: screenshot-processor INPUT OUTPUT DEVICE SCREEN_NAME\n".utf8)
            )
            exit(64)
        }

        try ScreenshotProcessor().process(
            input: URL(fileURLWithPath: arguments[1]),
            output: URL(fileURLWithPath: arguments[2]),
            device: device,
            screenName: arguments[4]
        )
    }
}
