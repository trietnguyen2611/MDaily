import SwiftUI
import UIKit

@MainActor
public struct FullScreenImageViewer: View {
    public var uiImage: UIImage
    public var onDismiss: () -> Void

    @State private var isDraggingDown: Bool = false
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

            // Native Apple Photos Grade Zoomable & 2D Pannable ScrollView
            ZoomableScrollView(
                image: uiImage,
                onDismiss: onDismiss,
                isDraggingDown: $isDraggingDown,
                dragOffset: $dragOffset,
                backgroundOpacity: $backgroundOpacity
            )
            .offset(y: dragOffset)
            .scaleEffect(isDraggingDown ? max(0.85, 1.0 - (dragOffset / 1200.0)) : (isAppearing ? 1.0 : 0.94))
            .opacity(isAppearing ? 1.0 : 0.0)

            // Header with Gesture Hint & Minimalist Close Button
            HStack(alignment: .center) {
                HStack(spacing: 6) {
                    Image(systemName: "hand.draw")
                        .font(.system(size: 11))
                    Text("Vuốt xuống để đóng • Phóng to & di chuyển tự do")
                        .font(.appFont(size: 12, weight: .medium))
                }
                .foregroundColor(.white.opacity(0.75))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Capsule().fill(Color.black.opacity(0.35)))

                Spacer()

                LiquidGlassCloseButton(size: 36, color: .white) {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                        backgroundOpacity = 0
                        isAppearing = false
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.20) {
                        onDismiss()
                    }
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 14)
            .opacity(isDraggingDown ? 0 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isDraggingDown)
        }
        .onAppear {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                isAppearing = true
            }
        }
    }
}

// MARK: - Native iOS 2D Free-Panning & Zooming ScrollView (UIViewRepresentable)
struct ZoomableScrollView: UIViewRepresentable {
    let image: UIImage
    let onDismiss: () -> Void
    @Binding var isDraggingDown: Bool
    @Binding var dragOffset: CGFloat
    @Binding var backgroundOpacity: Double

    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.delegate = context.coordinator
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 5.0
        scrollView.bouncesZoom = true
        scrollView.alwaysBounceVertical = false
        scrollView.alwaysBounceHorizontal = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.backgroundColor = .clear
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.decelerationRate = .normal

        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.isUserInteractionEnabled = true
        scrollView.addSubview(imageView)
        context.coordinator.imageView = imageView
        context.coordinator.scrollView = scrollView

        // Double Tap Zoom
        let doubleTap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleDoubleTap(_:)))
        doubleTap.numberOfTapsRequired = 2
        scrollView.addGestureRecognizer(doubleTap)

        // Pan Gesture for interactive drag-down dismiss
        let panGesture = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePan(_:)))
        panGesture.delegate = context.coordinator
        scrollView.addGestureRecognizer(panGesture)

        return scrollView
    }

    func updateUIView(_ uiView: UIScrollView, context: Context) {
        context.coordinator.imageView?.image = image
        context.coordinator.updateLayout(in: uiView)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIScrollViewDelegate, UIGestureRecognizerDelegate {
        var parent: ZoomableScrollView
        weak var scrollView: UIScrollView?
        weak var imageView: UIImageView?

        init(_ parent: ZoomableScrollView) {
            self.parent = parent
        }

        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            return imageView
        }

        func scrollViewDidZoom(_ scrollView: UIScrollView) {
            centerImage(in: scrollView)
        }

        func updateLayout(in scrollView: UIScrollView) {
            guard let imageView = imageView, let image = imageView.image else { return }
            let boundsSize = scrollView.bounds.size
            guard boundsSize.width > 0 && boundsSize.height > 0 else { return }

            let imageSize = image.size
            let widthRatio = boundsSize.width / imageSize.width
            let heightRatio = boundsSize.height / imageSize.height
            let scale = min(widthRatio, heightRatio)

            let scaledWidth = imageSize.width * scale
            let scaledHeight = imageSize.height * scale
            imageView.frame = CGRect(x: 0, y: 0, width: scaledWidth, height: scaledHeight)
            scrollView.contentSize = CGSize(width: scaledWidth, height: scaledHeight)
            centerImage(in: scrollView)
        }

        func centerImage(in scrollView: UIScrollView) {
            guard let imageView = imageView else { return }
            let boundsSize = scrollView.bounds.size
            var frameToCenter = imageView.frame

            if frameToCenter.size.width < boundsSize.width {
                frameToCenter.origin.x = (boundsSize.width - frameToCenter.size.width) / 2
            } else {
                frameToCenter.origin.x = 0
            }

            if frameToCenter.size.height < boundsSize.height {
                frameToCenter.origin.y = (boundsSize.height - frameToCenter.size.height) / 2
            } else {
                frameToCenter.origin.y = 0
            }

            imageView.frame = frameToCenter
        }

        @objc func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
            guard let scrollView = scrollView else { return }
            if scrollView.zoomScale > 1.1 {
                scrollView.setZoomScale(1.0, animated: true)
            } else {
                let point = gesture.location(in: imageView)
                let zoomRect = zoomRectForScale(scale: 2.6, center: point)
                scrollView.zoom(to: zoomRect, animated: true)
            }
        }

        private func zoomRectForScale(scale: CGFloat, center: CGPoint) -> CGRect {
            guard let scrollView = scrollView else { return .zero }
            var zoomRect = CGRect.zero
            zoomRect.size.height = scrollView.frame.size.height / scale
            zoomRect.size.width = scrollView.frame.size.width / scale
            zoomRect.origin.x = center.x - (zoomRect.size.width / 2.0)
            zoomRect.origin.y = center.y - (zoomRect.size.height / 2.0)
            return zoomRect
        }

        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            if let scrollView = scrollView, scrollView.zoomScale > 1.02 {
                return false
            }
            return true
        }

        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            guard let scrollView = scrollView, scrollView.zoomScale <= 1.02 else { return }
            let translation = gesture.translation(in: scrollView)

            switch gesture.state {
            case .changed:
                if translation.y > 0 {
                    DispatchQueue.main.async {
                        self.parent.isDraggingDown = true
                        self.parent.dragOffset = translation.y
                        let progress = Double(translation.y / 340.0)
                        self.parent.backgroundOpacity = max(0.15, 1.0 - progress)
                    }
                }
            case .ended, .cancelled:
                let velocity = gesture.velocity(in: scrollView)
                if translation.y > 90 || velocity.y > 650 {
                    withAnimation(.easeOut(duration: 0.22)) {
                        self.parent.dragOffset = scrollView.bounds.height
                        self.parent.backgroundOpacity = 0
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.20) {
                        self.parent.onDismiss()
                    }
                } else {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                        self.parent.dragOffset = 0
                        self.parent.backgroundOpacity = 1.0
                        self.parent.isDraggingDown = false
                    }
                }
            default:
                break
            }
        }
    }
}
