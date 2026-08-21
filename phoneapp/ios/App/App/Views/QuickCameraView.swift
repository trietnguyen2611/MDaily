import SwiftUI
import AVFoundation
import Vision

@MainActor
public struct QuickCameraView: View {
    public var onPhotoCaptured: (Data) -> Void
    public var onDismiss: () -> Void

    @StateObject private var camera = CameraController()
    @State private var receiptDetected: Bool = false
    @State private var receiptDetectionEnabled: Bool = true
    @State private var showReceiptBanner: Bool = false
    @State private var flashMode: AVCaptureDevice.FlashMode = .off

    public init(onPhotoCaptured: @escaping (Data) -> Void, onDismiss: @escaping () -> Void) {
        self.onPhotoCaptured = onPhotoCaptured
        self.onDismiss = onDismiss
    }

    public var body: some View {
        ZStack {
            // Camera Preview
            CameraPreviewRepresentable(session: camera.session)
                .ignoresSafeArea()

            // UI Overlay
            VStack(spacing: 0) {
                // Top Bar
                topBar
                    .padding(.top, 10)

                Spacer()

                // Receipt Detection Banner
                if showReceiptBanner && receiptDetectionEnabled {
                    receiptBanner
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .padding(.bottom, 12)
                }

                // Zoom Controls
                zoomControls
                    .padding(.bottom, 20)

                // Bottom Bar with Capture Button
                bottomBar
                    .padding(.bottom, 20)
            }
        }
        .onAppear {
            camera.startSession()
            camera.onReceiptDetected = { detected in
                if receiptDetectionEnabled {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        receiptDetected = detected
                        showReceiptBanner = detected
                    }
                    if detected {
                        let generator = UINotificationFeedbackGenerator()
                        generator.notificationOccurred(.success)
                        // Auto-hide banner after 3 seconds
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                            withAnimation { showReceiptBanner = false }
                        }
                    }
                }
            }
        }
        .onDisappear {
            camera.stopSession()
        }
        .statusBarHidden(true)
    }

    // MARK: - Top Bar
    private var topBar: some View {
        HStack {
            // Close button
            Button {
                onDismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(Color.black.opacity(0.45)))
            }

            Spacer()

            // Receipt detection toggle
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    receiptDetectionEnabled.toggle()
                    if !receiptDetectionEnabled {
                        showReceiptBanner = false
                        receiptDetected = false
                    }
                }
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: receiptDetectionEnabled ? "doc.viewfinder.fill" : "doc.viewfinder")
                        .font(.system(size: 14, weight: .semibold))
                    if receiptDetectionEnabled {
                        Text("ON")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                    }
                }
                .foregroundColor(receiptDetectionEnabled ? .green : .white.opacity(0.6))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Capsule().fill(Color.black.opacity(0.45)))
            }

            // Flash toggle
            Button {
                switch flashMode {
                case .off: flashMode = .on
                case .on: flashMode = .auto
                case .auto: flashMode = .off
                @unknown default: flashMode = .off
                }
                camera.flashMode = flashMode
            } label: {
                Image(systemName: flashIconName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(flashMode == .off ? .white.opacity(0.6) : .yellow)
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(Color.black.opacity(0.45)))
            }
        }
        .padding(.horizontal, 20)
    }

    private var flashIconName: String {
        switch flashMode {
        case .off: return "bolt.slash.fill"
        case .on: return "bolt.fill"
        case .auto: return "bolt.badge.automatic.fill"
        @unknown default: return "bolt.slash.fill"
        }
    }

    // MARK: - Receipt Detection Banner
    private var receiptBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "doc.text.viewfinder")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.green)

            Text("📄 Phát hiện hoá đơn!")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            Capsule()
                .fill(Color.black.opacity(0.70))
                .overlay(
                    Capsule()
                        .strokeBorder(Color.green.opacity(0.40), lineWidth: 1)
                )
        )
        .shadow(color: Color.green.opacity(0.25), radius: 8, x: 0, y: 4)
    }

    // MARK: - Zoom Controls
    private var zoomControls: some View {
        HStack(spacing: 14) {
            ForEach([0.5, 1.0, 2.0, 3.0], id: \.self) { level in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        camera.setZoom(factor: level)
                    }
                } label: {
                    let isActive = abs(camera.currentZoom - level) < 0.1
                    Text(level == 0.5 ? ".5" : "\(Int(level))")
                        .font(.system(size: isActive ? 14 : 12, weight: .bold, design: .rounded))
                        .foregroundColor(isActive ? .yellow : .white.opacity(0.7))
                        .frame(width: isActive ? 40 : 34, height: isActive ? 40 : 34)
                        .background(
                            Circle()
                                .fill(isActive ? Color.black.opacity(0.65) : Color.black.opacity(0.35))
                                .overlay(
                                    Circle()
                                        .strokeBorder(isActive ? Color.yellow.opacity(0.50) : Color.white.opacity(0.15), lineWidth: 0.75)
                                )
                        )
                }
            }
        }
    }

    // MARK: - Bottom Bar
    private var bottomBar: some View {
        HStack {
            // Spacer for symmetry
            Color.clear.frame(width: 60, height: 60)

            Spacer()

            // Capture Button
            Button {
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
                camera.capturePhoto { data in
                    if let data = data {
                        onPhotoCaptured(data)
                        onDismiss()
                    }
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 72, height: 72)
                        .shadow(color: Color.white.opacity(0.3), radius: 8, x: 0, y: 0)

                    Circle()
                        .strokeBorder(Color.white.opacity(0.5), lineWidth: 3)
                        .frame(width: 82, height: 82)
                }
            }
            .liquidGlassButton()

            Spacer()

            // Flip Camera
            Button {
                camera.switchCamera()
            } label: {
                Image(systemName: "camera.rotate.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 50, height: 50)
                    .background(Circle().fill(Color.black.opacity(0.45)))
            }
        }
        .padding(.horizontal, 30)
    }
}

// MARK: - Camera Preview UIViewRepresentable
struct CameraPreviewRepresentable: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> UIView {
        let view = CameraPreviewUIView()
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}

private class CameraPreviewUIView: UIView {
    override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
    var previewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
}

// MARK: - Camera Controller
@MainActor
class CameraController: NSObject, ObservableObject {
    let session = AVCaptureSession()
    private var photoOutput = AVCapturePhotoOutput()
    private var videoOutput = AVCaptureVideoDataOutput()
    private var currentDevice: AVCaptureDevice?
    private var isUsingFrontCamera = false
    private var photoCaptureCompletion: ((Data?) -> Void)?
    private var receiptDetectionTimer: Timer?

    @Published var currentZoom: Double = 1.0
    var flashMode: AVCaptureDevice.FlashMode = .off
    var onReceiptDetected: ((Bool) -> Void)?

    private let sessionQueue = DispatchQueue(label: "org.mdaily.camera.session")

    override init() {
        super.init()
    }

    func startSession() {
        sessionQueue.async { [weak self] in
            self?.configureSession()
            self?.session.startRunning()
        }
    }

    func stopSession() {
        sessionQueue.async { [weak self] in
            self?.session.stopRunning()
        }
        receiptDetectionTimer?.invalidate()
        receiptDetectionTimer = nil
    }

    private func configureSession() {
        session.beginConfiguration()
        session.sessionPreset = .photo

        // Remove existing inputs/outputs
        session.inputs.forEach { session.removeInput($0) }
        session.outputs.forEach { session.removeOutput($0) }

        // Add camera input
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: device) else {
            session.commitConfiguration()
            return
        }

        if session.canAddInput(input) {
            session.addInput(input)
            currentDevice = device
        }

        // Add photo output
        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
            photoOutput.isHighResolutionCaptureEnabled = true
        }

        // Add video output for receipt detection
        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
            videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "org.mdaily.camera.video"))
            videoOutput.alwaysDiscardsLateVideoFrames = true
        }

        session.commitConfiguration()
    }

    func setZoom(factor: Double) {
        guard let device = currentDevice else { return }
        let clampedFactor = max(device.minAvailableVideoZoomFactor, min(factor, min(device.maxAvailableVideoZoomFactor, 10.0)))
        do {
            try device.lockForConfiguration()
            device.videoZoomFactor = clampedFactor
            device.unlockForConfiguration()
            DispatchQueue.main.async {
                self.currentZoom = clampedFactor
            }
        } catch {}
    }

    func switchCamera() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            self.isUsingFrontCamera.toggle()
            let position: AVCaptureDevice.Position = self.isUsingFrontCamera ? .front : .back

            self.session.beginConfiguration()
            self.session.inputs.forEach { self.session.removeInput($0) }

            guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position),
                  let input = try? AVCaptureDeviceInput(device: device) else {
                self.session.commitConfiguration()
                return
            }

            if self.session.canAddInput(input) {
                self.session.addInput(input)
                self.currentDevice = device
            }
            self.session.commitConfiguration()

            DispatchQueue.main.async {
                self.currentZoom = 1.0
            }
        }
    }

    func capturePhoto(completion: @escaping (Data?) -> Void) {
        photoCaptureCompletion = completion
        let settings = AVCapturePhotoSettings()
        settings.flashMode = flashMode
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
}

// MARK: - Photo Capture Delegate
extension CameraController: AVCapturePhotoCaptureDelegate {
    nonisolated func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        let data = photo.fileDataRepresentation()
        Task { @MainActor in
            self.photoCaptureCompletion?(data)
            self.photoCaptureCompletion = nil
        }
    }
}

// MARK: - Video Frame Delegate (for receipt detection)
extension CameraController: AVCaptureVideoDataOutputSampleBufferDelegate {
    nonisolated func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // Throttle: Only check every ~0.5 seconds by skipping frames
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        // Use VNDetectRectanglesRequest to detect document-like rectangles
        let request = VNDetectRectanglesRequest { request, error in
            guard error == nil,
                  let results = request.results as? [VNRectangleObservation],
                  !results.isEmpty else {
                Task { @MainActor in
                    self.onReceiptDetected?(false)
                }
                return
            }

            // Check if any detected rectangle is large enough to be a receipt
            let hasLargeRect = results.contains { observation in
                let area = observation.boundingBox.width * observation.boundingBox.height
                return area > 0.15 // At least 15% of image area
            }

            Task { @MainActor in
                self.onReceiptDetected?(hasLargeRect)
            }
        }
        request.minimumSize = 0.2
        request.maximumObservations = 3
        request.minimumConfidence = 0.7

        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        try? handler.perform([request])
    }
}
