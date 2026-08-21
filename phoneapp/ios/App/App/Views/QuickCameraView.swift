import SwiftUI
import AVFoundation

@MainActor
public struct QuickCameraView: View {
    public var onPhotoCaptured: (Data) -> Void
    public var onDismiss: () -> Void

    @StateObject private var camera = CameraController()
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
                    .padding(.top, 56)

                Spacer()

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
class CameraController: NSObject, ObservableObject, @unchecked Sendable {
    let session = AVCaptureSession()
    private var photoOutput = AVCapturePhotoOutput()
    private var currentDevice: AVCaptureDevice?
    private var isUsingFrontCamera = false
    private var photoCaptureCompletion: ((Data?) -> Void)?

    @Published var currentZoom: Double = 1.0
    var flashMode: AVCaptureDevice.FlashMode = .off

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
