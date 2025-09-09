import SwiftUI
import UIKit

// A SwiftUI view that wraps a UIControl which performs alpha-based hit testing
struct AlphaHitTestButton: UIViewRepresentable {
    let imageName: String
    let alphaThreshold: CGFloat
    let action: () -> Void
    
    init(imageName: String, alphaThreshold: CGFloat = 0.1, action: @escaping () -> Void) {
        self.imageName = imageName
        self.alphaThreshold = alphaThreshold
        self.action = action
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(action: action)
    }
    
    func makeUIView(context: Context) -> AlphaButton {
        let uiImage = UIImage(named: imageName) ?? UIImage()
        let button = AlphaButton(image: uiImage, alphaThreshold: alphaThreshold)
        button.addTarget(context.coordinator, action: #selector(Coordinator.handleTap), for: .touchUpInside)
        return button
    }
    
    func updateUIView(_ uiView: AlphaButton, context: Context) {
        // No dynamic updates needed for now
    }
    
    class Coordinator {
        let action: () -> Void
        
        init(action: @escaping () -> Void) {
            self.action = action
        }
        
        @objc func handleTap() {
            action()
        }
    }
}

// UIControl that only returns true for touches on non-transparent pixels of its image
final class AlphaButton: UIControl {
    private let imageView: UIImageView
    private let alphaThreshold: CGFloat
    
    init(image: UIImage, alphaThreshold: CGFloat) {
        self.imageView = UIImageView(image: image)
        self.alphaThreshold = alphaThreshold
        super.init(frame: .zero)
        isOpaque = false
        clipsToBounds = false
        backgroundColor = .clear
        imageView.backgroundColor = .clear
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        // Accessibility: treat as button
        isAccessibilityElement = true
        accessibilityTraits.insert(.button)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        guard bounds.contains(point) else { return false }
        guard let image = imageView.image, let cgImage = image.cgImage else { return false }
        
        // Compute the rect the image occupies inside the imageView when using aspectFit
        let viewSize = imageView.bounds.size
        let imageSize = CGSize(width: cgImage.width, height: cgImage.height)
        if viewSize.width <= 0 || viewSize.height <= 0 || imageSize.width <= 0 || imageSize.height <= 0 {
            return false
        }
        let scale = min(viewSize.width / imageSize.width, viewSize.height / imageSize.height)
        let scaledImageSize = CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
        let imageOrigin = CGPoint(
            x: (viewSize.width - scaledImageSize.width) / 2.0,
            y: (viewSize.height - scaledImageSize.height) / 2.0
        )
        
        // If the touch is outside the drawn image area, it's transparent
        let pointInImageRect = CGPoint(x: point.x - imageOrigin.x, y: point.y - imageOrigin.y)
        if pointInImageRect.x < 0 || pointInImageRect.y < 0 || pointInImageRect.x > scaledImageSize.width || pointInImageRect.y > scaledImageSize.height {
            return false
        }
        
        // Map to pixel coordinates in the original image
        let pixelX = Int((pointInImageRect.x / scale).rounded(.down))
        let pixelYFromTop = Int((pointInImageRect.y / scale).rounded(.down))
        
        // CoreGraphics image origin is bottom-left; convert from top-left
        let pixelY = cgImage.height - 1 - pixelYFromTop
        if pixelX < 0 || pixelY < 0 || pixelX >= cgImage.width || pixelY >= cgImage.height { return false }
        
        // Sample the alpha at the pixel by rendering into a 1x1 context
        var pixel: [UInt8] = [0, 0, 0, 0]
        guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) else { return false }
        guard let context = CGContext(
            data: &pixel,
            width: 1,
            height: 1,
            bitsPerComponent: 8,
            bytesPerRow: 4,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return false
        }
        
        // Translate so that the desired pixel lands at (0,0) when drawing
        context.interpolationQuality = .none
        context.translateBy(x: -CGFloat(pixelX), y: -CGFloat(pixelY))
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: CGFloat(cgImage.width), height: CGFloat(cgImage.height)))
        let alpha = CGFloat(pixel[3]) / 255.0
        return alpha >= alphaThreshold
    }
}


