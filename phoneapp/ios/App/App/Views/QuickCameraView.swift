import SwiftUI
import AVFoundation

@MainActor
public struct QuickCameraView: View {
    @ObservedObject public var store: ExpenseStore
    public var onPhotoCaptured: (Data) -> Void
    public var onDismiss: () -> Void

    @StateObject private var camera = CameraController()
    @State private var flashMode: AVCaptureDevice.FlashMode = .off
    @State private var isExpanded: Bool = false
    @State private var dragOffset: CGSize = .zero

    public init(store: ExpenseStore, onPhotoCaptured: @escaping (Data) -> Void, onDismiss: @escaping () -> Void) {
        self.store = store
        self.onPhotoCaptured = onPhotoCaptured
        self.onDismiss = onDismiss
    }

    public var body: some View {
        if store.cameraLayoutMode == .dynamicIsland {
            dynamicIslandCameraBody
        } else {
            defaultCameraBody
        }
    }

    // MARK: - Dynamic Island Camera Body
    private var dynamicIslandCameraBody: some View {
        let screenWidth = UIScreen.main.bounds.width
        let cardWidth = screenWidth - 20
        let previewWidth = cardWidth - 20
        let previewHeight = previewWidth * 4.0 / 3.0 // Default 3:4 portrait photo ratio

        // Native iOS physics: morph scale and corners based on drag-up distance
        let dragProgress = min(1.0, max(0.0, -dragOffset.height / 150.0)) // 0.0 to 1.0 based on 150pt threshold
        let scaleX = 1.0 - (dragProgress * 0.18) // Squish width down by up to 18%
        let scaleY = 1.0 - (dragProgress * 0.12) // Squish height down by up to 12%
        let cornerRadius = 42.0 + (dragProgress * (16.0 - 42.0)) // Morph corner radius back to pill (16)
        let shadowOpacity = 0.35 - (dragProgress * 0.20)
        let shadowRadius = 15.0 - (dragProgress * 7.0)

        return ZStack {
            // 1. Transparent Backdrop overlay (captures taps outside card to close, but keeps app visible)
            Color.clear
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture {
                    if isExpanded {
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.88)) {
                            isExpanded = false
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.30) {
                            onDismiss()
                        }
                    }
                }

            // 2. Dynamic Island Expanding Square Camera Card
            VStack(spacing: 0) {
                VStack(spacing: 0) {
                    if isExpanded {
                        VStack(spacing: 12) {
                            // Top controls bar inside the expanded island card
                            HStack {
                                Spacer()

                                // Close Button (Right, Colored Red!)
                                Button {
                                    withAnimation(.spring(response: 0.32, dampingFraction: 0.88)) {
                                        isExpanded = false
                                    }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.30) {
                                        onDismiss()
                                    }
                                } label: {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 15, weight: .bold))
                                        .foregroundColor(.red)
                                        .frame(width: 34, height: 34)
                                        .background(Circle().fill(Color.white.opacity(0.15)))
                                }
                                .transition(.scale.combined(with: .opacity))
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 14)

                            // Camera Preview (Default 3:4 portrait photo aspect ratio)
                            CameraPreviewRepresentable(session: camera.session)
                                .frame(width: previewWidth, height: previewHeight)
                                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                                .transition(.opacity.combined(with: .scale(scale: 0.95)))

                            // Bottom actions layout (Zoom + Rotate/Capture row)
                            VStack(spacing: 14) {
                                // Native zoom selector
                                HStack(spacing: 12) {
                                    ForEach([0.5, 1.0, 2.0, 3.0], id: \.self) { level in
                                        Button {
                                            withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                                                camera.setZoom(factor: level)
                                            }
                                        } label: {
                                            let isActive = abs(camera.currentZoom - level) < 0.1
                                            Text(level == 0.5 ? ".5" : "\(Int(level))")
                                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                                .foregroundColor(isActive ? .yellow : .white.opacity(0.7))
                                                .frame(width: 32, height: 32)
                                                .background(Circle().fill(isActive ? Color.white.opacity(0.20) : Color.white.opacity(0.08)))
                                        }
                                    }
                                }
                                .transition(.opacity)

                                // Rotate, Center Capture, and Flash Button
                                HStack {
                                    // Rotate Camera (left)
                                    Button {
                                        camera.switchCamera()
                                    } label: {
                                        Image(systemName: "camera.rotate.fill")
                                            .font(.system(size: 18))
                                            .foregroundColor(.white)
                                            .frame(width: 44, height: 44)
                                            .background(Circle().fill(Color.white.opacity(0.15)))
                                    }
                                    .padding(.leading, 16)
                                    .transition(.scale.combined(with: .opacity))

                                    Spacer()

                                    // Capture Photo Button (center)
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
                                                .frame(width: 56, height: 56)
                                            Circle()
                                                .strokeBorder(Color.white.opacity(0.5), lineWidth: 2)
                                                .frame(width: 66, height: 66)
                                        }
                                    }
                                    .transition(.scale.combined(with: .opacity))

                                    Spacer()

                                    // Flash toggle (right)
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
                                            .font(.system(size: 18, weight: .semibold))
                                            .foregroundColor(flashMode == .off ? .white.opacity(0.6) : .yellow)
                                            .frame(width: 44, height: 44)
                                            .background(Circle().fill(Color.white.opacity(0.15)))
                                    }
                                    .padding(.trailing, 16)
                                    .transition(.scale.combined(with: .opacity))
                                }
                            }
                            .padding(.bottom, 16)
                        }
                    } else {
                        // Collapsed State: exact Dynamic Island frame
                        ZStack {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 5, height: 5)
                        }
                        .frame(width: 110, height: 32)
                    }
                }
                .frame(
                    width: isExpanded ? cardWidth : 110,
                    height: isExpanded ? nil : 32
                )
                .background(Color.black)
                .scaleEffect(x: isExpanded ? scaleX : 1.0, y: isExpanded ? scaleY : 1.0, anchor: .top)
                .clipShape(RoundedRectangle(cornerRadius: isExpanded ? cornerRadius : 16, style: .continuous))
                .shadow(color: Color.black.opacity(shadowOpacity), radius: shadowRadius, x: 0, y: 8)
                .offset(y: dragOffset.height + 11)
                .gesture(
                    DragGesture()
                        .onChanged { gesture in
                            if gesture.translation.height < 0 {
                                dragOffset = gesture.translation
                            }
                        }
                        .onEnded { gesture in
                            if gesture.translation.height < -70 {
                                withAnimation(.spring(response: 0.32, dampingFraction: 0.88)) {
                                    isExpanded = false
                                    dragOffset = .zero
                                }
                                superClassDismiss()
                            } else {
                                withAnimation(.spring(response: 0.40, dampingFraction: 0.70)) {
                                    dragOffset = .zero
                                }
                            }
                        }
                )

                Spacer()
            }
            .ignoresSafeArea(edges: .top)
        }
        .onAppear {
            camera.startSession()
            withAnimation(.spring(response: 0.46, dampingFraction: 0.66, blendDuration: 0.1)) {
                isExpanded = true
            }
        }
        .onDisappear {
            camera.stopSession()
            isExpanded = false
        }
        .statusBarHidden(true)
    }

    // MARK: - Default Full Screen Camera Body
    private var defaultCameraBody: some View {
        ZStack {
            // Live Preview takes up full screen
            CameraPreviewRepresentable(session: camera.session)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Top bar
                HStack {
                    // Flash toggle (Left)
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
                            .foregroundColor(flashMode == .off ? .white.opacity(0.8) : .yellow)
                            .frame(width: 40, height: 40)
                            .background(Circle().fill(Color.black.opacity(0.4)))
                    }

                    Spacer()

                    // Close Button (Right, Colored Red!)
                    Button {
                        onDismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.red)
                            .frame(width: 40, height: 40)
                            .background(Circle().fill(Color.black.opacity(0.4)))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)

                Spacer()

                // Bottom actions layout (Zoom + Rotate/Capture row)
                VStack(spacing: 16) {
                    // Zoom selector
                    HStack(spacing: 12) {
                        ForEach([0.5, 1.0, 2.0, 3.0], id: \.self) { level in
                            Button {
                                withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                                    camera.setZoom(factor: level)
                                }
                            } label: {
                                let isActive = abs(camera.currentZoom - level) < 0.1
                                Text(level == 0.5 ? ".5" : "\(Int(level))")
                                    .font(.system(size: 12, weight: .bold, design: .rounded))
                                    .foregroundColor(isActive ? .yellow : .white)
                                    .frame(width: 32, height: 32)
                                    .background(Circle().fill(isActive ? Color.black.opacity(0.65) : Color.black.opacity(0.35)))
                            }
                        }
                    }

                    // Rotate and Capture Button row
                    HStack {
                        // Rotate Camera (left)
                        Button {
                            camera.switchCamera()
                        } label: {
                            Image(systemName: "camera.rotate.fill")
                                .font(.system(size: 18))
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(Circle().fill(Color.black.opacity(0.4)))
                        }
                        .padding(.leading, 30)

                        Spacer()

                        // Capture Photo Button (center)
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
                                    .frame(width: 62, height: 62)
                                Circle()
                                    .strokeBorder(Color.white, lineWidth: 3)
                                    .frame(width: 74, height: 74)
                            }
                        }

                        Spacer()

                        // Symmetry placeholder
                        Color.clear
                            .frame(width: 44, height: 44)
                            .padding(.trailing, 30)
                    }
                }
                .padding(.bottom, 36)
                .background(
                    LinearGradient(
                        colors: [Color.clear, Color.black.opacity(0.6)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
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

    private func superClassDismiss() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.30) {
            onDismiss()
        }
    }

    private var flashIconName: String {
        switch flashMode {
        case .off: return "bolt.slash.fill"
        case .on: return "bolt.fill"
        case .auto: return "bolt.badge.automatic.fill"
        @unknown default: return "bolt.slash.fill"
        }
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
