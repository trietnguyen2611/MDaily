import SwiftUI
import UIKit

@MainActor
public struct FullScreenImageViewer: View {
    public var uiImage: UIImage
    public var onDismiss: () -> Void

    @State private var dragOffset: CGFloat = 0
    @State private var backgroundOpacity: Double = 1.0
    @State private var isAppearing: Bool = false

    public init(uiImage: UIImage, onDismiss: @escaping () -> Void) {
        self.uiImage = uiImage
        self.onDismiss = onDismiss
    }

    public var body: some View {
        ZStack(alignment: .topTrailing) {
            // Smooth Ambient Dark Backdrop
            Color.black
                .opacity(backgroundOpacity)
                .ignoresSafeArea()

            // Native Apple Photos Grade Auto-Fitting 2D Zoomable & Pannable ScrollView
            ZoomableImageScrollView(
                image: uiImage,
                onDismiss: onDismiss,
                dragOffset: $dragOffset,
                backgroundOpacity: $backgroundOpacity
            )
            .opacity(isAppearing ? 1.0 : 0.0)
            .scaleEffect(isAppearing ? 1.0 : 0.96)

            // Top Header: iOS system circle close button only (no hint text)
            HStack {
                Spacer()

                Button {
                    dismissWithAnimation()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 30))
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.white, Color.white.opacity(0.30))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 18)
            .padding(.top, 14)
            .opacity(dragOffset > 10 ? 0.0 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: dragOffset > 10)
        }
        .onAppear {
            withAnimation(.spring(response: 0.32, dampingFraction: 0.85)) {
                isAppearing = true
            }
        }
    }

    private func dismissWithAnimation() {
        withAnimation(.easeOut(duration: 0.22)) {
            backgroundOpacity = 0
            isAppearing = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.20) {
            onDismiss()
        }
    }
}

// MARK: - Native iOS Auto-Fitting 2D Zoom & Pan View (UIKit Implementation)
struct ZoomableImageScrollView: UIViewRepresentable {
    let image: UIImage
    let onDismiss: () -> Void
    @Binding var dragOffset: CGFloat
    @Binding var backgroundOpacity: Double

    func makeUIView(context: Context) -> CenteredZoomScrollView {
        let scrollView = CenteredZoomScrollView(image: image)
        scrollView.onDismissRequest = {
            DispatchQueue.main.async {
                self.onDismiss()
            }
        }
        scrollView.onDragProgress = { offset, opacity in
            DispatchQueue.main.async {
                self.dragOffset = offset
                self.backgroundOpacity = opacity
            }
        }
        return scrollView
    }

    func updateUIView(_ uiView: CenteredZoomScrollView, context: Context) {
        uiView.updateImage(image)
    }
}

// MARK: - Custom Centered Zoom ScrollView
final class CenteredZoomScrollView: UIScrollView, UIScrollViewDelegate {
    let imageView = UIImageView()
    var onDismissRequest: (() -> Void)?
    var onDragProgress: ((CGFloat, Double) -> Void)?

    private var initialFitDone = false
    private var lastBoundsSize: CGSize = .zero

    init(image: UIImage) {
        super.init(frame: .zero)
        self.delegate = self
        self.minimumZoomScale = 1.0
        self.maximumZoomScale = 5.0
        self.zoomScale = 1.0
        self.bouncesZoom = true
        self.alwaysBounceVertical = true
        self.alwaysBounceHorizontal = false
        self.showsHorizontalScrollIndicator = false
        self.showsVerticalScrollIndicator = false
        self.backgroundColor = .clear
        self.contentInsetAdjustmentBehavior = .never
        self.decelerationRate = .normal

        imageView.image = image
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.isUserInteractionEnabled = true
        addSubview(imageView)

        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
        doubleTap.numberOfTapsRequired = 2
        addGestureRecognizer(doubleTap)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        if bounds.size != lastBoundsSize && bounds.width > 0 && bounds.height > 0 {
            lastBoundsSize = bounds.size
            if let img = imageView.image {
                fitImageToScreen(image: img)
            }
        } else {
            centerImage()
        }
    }

    func updateImage(_ newImage: UIImage) {
        if imageView.image !== newImage {
            imageView.image = newImage
            initialFitDone = false
            lastBoundsSize = .zero
            setNeedsLayout()
        }
    }

    private func fitImageToScreen(image: UIImage) {
        let boundsSize = bounds.size
        guard boundsSize.width > 0 && boundsSize.height > 0 else { return }

        let imageSize = image.size
        guard imageSize.width > 0 && imageSize.height > 0 else { return }

        let widthRatio = boundsSize.width / imageSize.width
        let heightRatio = boundsSize.height / imageSize.height
        let scale = min(widthRatio, heightRatio)

        let fitWidth = floor(imageSize.width * scale)
        let fitHeight = floor(imageSize.height * scale)

        self.zoomScale = 1.0
        imageView.frame = CGRect(
            x: (boundsSize.width - fitWidth) / 2.0,
            y: (boundsSize.height - fitHeight) / 2.0,
            width: fitWidth,
            height: fitHeight
        )
        self.contentSize = CGSize(width: fitWidth, height: fitHeight)
        centerImage()
    }

    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }

    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        centerImage()
    }

    private func centerImage() {
        let boundsSize = bounds.size
        var frameToCenter = imageView.frame

        if frameToCenter.size.width < boundsSize.width {
            frameToCenter.origin.x = (boundsSize.width - frameToCenter.size.width) / 2.0
        } else {
            frameToCenter.origin.x = 0
        }

        if frameToCenter.size.height < boundsSize.height {
            frameToCenter.origin.y = (boundsSize.height - frameToCenter.size.height) / 2.0
        } else {
            frameToCenter.origin.y = 0
        }

        imageView.frame = frameToCenter
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if zoomScale <= 1.01 {
            let offsetY = scrollView.contentOffset.y
            if offsetY < 0 {
                let pullDistance = -offsetY
                let progress = Double(pullDistance / 280.0)
                let opacity = max(0.20, 1.0 - progress)
                onDragProgress?(pullDistance, opacity)
            } else {
                onDragProgress?(0, 1.0)
            }
        }
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if zoomScale <= 1.01 {
            let pullDistance = -scrollView.contentOffset.y
            if pullDistance > 75 {
                onDismissRequest?()
            } else {
                onDragProgress?(0, 1.0)
            }
        }
    }

    @objc private func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
        if zoomScale > 1.05 {
            setZoomScale(1.0, animated: true)
        } else {
            let pointInView = gesture.location(in: imageView)
            let newZoomScale: CGFloat = 2.8
            let scrollViewSize = bounds.size

            let width = scrollViewSize.width / newZoomScale
            let height = scrollViewSize.height / newZoomScale
            let originX = pointInView.x - (width / 2.0)
            let originY = pointInView.y - (height / 2.0)

            let rectToZoomTo = CGRect(x: originX, y: originY, width: width, height: height)
            zoom(to: rectToZoomTo, animated: true)
        }
    }
}
