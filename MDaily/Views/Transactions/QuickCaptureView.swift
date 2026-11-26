import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

#if os(iOS)
@preconcurrency import AVFoundation
import UIKit
#endif

@MainActor
public struct QuickCaptureView: View {
    @ObservedObject public var store: FinanceStore
    public var onPhotoCaptured: (Data) -> Void
    public var onDismiss: () -> Void

    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var showFileImporter: Bool = false
    @State private var isDropTargeted: Bool = false

    #if os(iOS)
    @StateObject private var camera = CameraCaptureController()
    @State private var flashMode: AVCaptureDevice.FlashMode = .off
    #endif

    public init(
        store: FinanceStore,
        onPhotoCaptured: @escaping (Data) -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self.store = store
        self.onPhotoCaptured = onPhotoCaptured
        self.onDismiss = onDismiss
    }

    private var isEnglish: Bool { store.language == .en }

    public var body: some View {
        Group {
            #if os(iOS)
            iOSCaptureBody
            #elseif os(macOS)
            macOSImportBody
            #endif
        }
        .onChange(of: selectedPhotoItem) { _, item in
            guard let item else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self) {
                    await MainActor.run {
                        onPhotoCaptured(data)
                        onDismiss()
                    }
                }
            }
        }
    }

    // MARK: - iOS Live Camera + Simulator Fallback

    #if os(iOS)
    @ViewBuilder
    private var iOSCaptureBody: some View {
        if CameraCaptureController.isCameraHardwareAvailable {
            ZStack {
                Color.black.ignoresSafeArea()

                CameraPreviewView(session: camera.session)
                    .ignoresSafeArea()

                VStack {
                    // Top bar
                    HStack {
                        Button {
                            cycleFlash()
                        } label: {
                            Image(systemName: flashIconName)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(flashMode == .off ? Color.white : Color.yellow)
                                .frame(width: 40, height: 40)
                                .mdailyGlassSurface(in: Circle(), interactive: true, tint: .black.opacity(0.2))
                        }
                        .buttonStyle(.plain)

                        Spacer()

                        Button(action: onDismiss) {
                            Image(systemName: "xmark")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(width: 40, height: 40)
                                .mdailyGlassSurface(in: Circle(), interactive: true, tint: .black.opacity(0.2))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)

                    Spacer()

                    // Bottom controls: zoom + library + capture + flip
                    VStack(spacing: 16) {
                        HStack(spacing: 8) {
                            ForEach([0.5, 1.0, 2.0, 3.0], id: \.self) { level in
                                let isActive = abs(camera.currentZoom - level) < 0.1
                                Button {
                                    camera.setZoom(factor: level)
                                } label: {
                                    Text(level == 0.5 ? ".5×" : "\(Int(level))×")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundStyle(isActive ? Color.yellow : Color.white)
                                        .frame(width: 34, height: 34)
                                        .mdailyGlassSurface(in: Circle(), interactive: true, tint: .black.opacity(0.2))
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        HStack(alignment: .center) {
                            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                                Image(systemName: "photo.on.rectangle")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundStyle(.white)
                                    .frame(width: 46, height: 46)
                                    .glassEffect(.regular.tint(.black.opacity(0.2)).interactive(), in: Circle())
                            }

                            Spacer()

                            Button {
                                camera.capturePhoto { data in
                                    if let data {
                                        onPhotoCaptured(data)
                                        onDismiss()
                                    }
                                }
                            } label: {
                                ZStack {
                                    Circle()
                                        .fill(Color.white)
                                        .frame(width: 64, height: 64)
                                    Circle()
                                        .strokeBorder(Color.white.opacity(0.85), lineWidth: 3)
                                        .frame(width: 76, height: 76)
                                }
                            }
                            .buttonStyle(MDailyPressButtonStyle())

                            Spacer()

                            Button {
                                camera.switchCamera()
                            } label: {
                                Image(systemName: "camera.rotate")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundStyle(.white)
                                    .frame(width: 46, height: 46)
                                    .mdailyGlassSurface(in: Circle(), interactive: true, tint: .black.opacity(0.2))
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 28)
                    }
                    .padding(.bottom, 32)
                }
            }
            .onAppear { camera.startSession() }
            .onDisappear { camera.stopSession() }
        } else {
            simulatorOrNoCameraFallback
        }
    }

    private var simulatorOrNoCameraFallback: some View {
        let english = isEnglish
        return VStack(spacing: 20) {
            HStack {
                Spacer()
                MDailyCloseButton(action: onDismiss)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)

            Spacer()

            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 36, weight: .regular))
                .foregroundStyle(Color.mdailyActionBlue)

            Text(english ? "Choose Photo" : "Chọn ảnh hoá đơn")
                .font(.system(size: 19, weight: .semibold))

            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                Label(
                    english ? "Photo Library" : "Thư viện ảnh",
                    systemImage: "photo.on.rectangle"
                )
                .font(.system(size: 15, weight: .semibold))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
            }
            .buttonBorderShape(.capsule)
            .mdailyGlassButton(prominent: true)

            Spacer()
        }
        .background(Color.mdailyCanvas.ignoresSafeArea())
    }

    private func cycleFlash() {
        switch flashMode {
        case .off: flashMode = .on
        case .on: flashMode = .auto
        case .auto: flashMode = .off
        @unknown default: flashMode = .off
        }
        camera.flashMode = flashMode
    }

    private var flashIconName: String {
        switch flashMode {
        case .off: return "bolt.slash.fill"
        case .on: return "bolt.fill"
        case .auto: return "bolt.badge.automatic.fill"
        @unknown default: return "bolt.slash.fill"
        }
    }
    #endif

    // MARK: - macOS Receipt Import / Drop Sheet

    #if os(macOS)
    private var macOSImportBody: some View {
        let english = isEnglish
        return VStack(spacing: 18) {
            HStack {
                Text(english ? "Import Receipt" : "Nhập hoá đơn")
                    .font(.system(size: 18, weight: .semibold))
                Spacer()
                MDailyCloseButton(action: onDismiss)
            }

            VStack(spacing: 14) {
                Image(systemName: "doc.viewfinder")
                    .font(.system(size: 34, weight: .regular))
                    .foregroundStyle(Color.mdailyActionBlue)

                Text(english ? "Drop Receipt Image" : "Thả ảnh hoá đơn")
                    .font(.system(size: 16, weight: .semibold))

                HStack(spacing: 12) {
                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        Label(english ? "Photos" : "Ảnh", systemImage: "photo.on.rectangle")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .buttonBorderShape(.capsule)
                    .mdailyGlassButton(prominent: true)

                    Button {
                        showFileImporter = true
                    } label: {
                        Label(english ? "Choose File…" : "Chọn tệp…", systemImage: "folder")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .buttonBorderShape(.capsule)
                    .mdailyGlassButton(prominent: false)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(24)
            .mdailyCard(cornerRadius: 18)
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(
                        isDropTargeted ? Color.mdailyActionBlue : Color.clear,
                        lineWidth: 2
                    )
            )
            .dropDestination(for: Data.self) { items, _ in
                guard let data = items.first, Image(platformImageData: data) != nil else {
                    return false
                }
                onPhotoCaptured(data)
                onDismiss()
                return true
            } isTargeted: { targeted in
                isDropTargeted = targeted
            }
        }
        .padding(22)
        .frame(minWidth: 420, minHeight: 320)
        .background(Color.mdailyCanvas)
        .fileImporter(
            isPresented: $showFileImporter,
            allowedContentTypes: [.image],
            allowsMultipleSelection: false
        ) { result in
            if case .success(let urls) = result, let url = urls.first {
                let needsAccess = url.startAccessingSecurityScopedResource()
                defer {
                    if needsAccess { url.stopAccessingSecurityScopedResource() }
                }
                if let data = try? Data(contentsOf: url) {
                    onPhotoCaptured(data)
                    onDismiss()
                }
            }
        }
    }
    #endif
}

// MARK: - iOS AVFoundation Camera Support

#if os(iOS)
private struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> CameraPreviewUIView {
        let view = CameraPreviewUIView()
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: CameraPreviewUIView, context: Context) {}
}

private final class CameraPreviewUIView: UIView {
    override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
    var previewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
}

private final class CameraCaptureController: NSObject, ObservableObject, @unchecked Sendable {
    let session = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private let sessionQueue = DispatchQueue(label: "com.mdaily.camera.session")

    private var currentDevice: AVCaptureDevice?
    private var isUsingFrontCamera = false
    private var photoCaptureCompletion: (@MainActor @Sendable (Data?) -> Void)?

    @Published var currentZoom: Double = 1.0
    var flashMode: AVCaptureDevice.FlashMode = .off

    static var isCameraHardwareAvailable: Bool {
        #if targetEnvironment(simulator)
        return false
        #else
        return AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) != nil
        #endif
    }

    func startSession() {
        guard Self.isCameraHardwareAvailable else { return }
        sessionQueue.async { [weak self] in
            self?.configureSession(position: .back)
            self?.session.startRunning()
        }
    }

    func stopSession() {
        sessionQueue.async { [weak self] in
            if self?.session.isRunning == true {
                self?.session.stopRunning()
            }
        }
    }

    private func configureSession(position: AVCaptureDevice.Position) {
        session.beginConfiguration()
        session.sessionPreset = .photo
        session.inputs.forEach { session.removeInput($0) }
        session.outputs.forEach { session.removeOutput($0) }

        if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position),
           let input = try? AVCaptureDeviceInput(device: device),
           session.canAddInput(input) {
            session.addInput(input)
            currentDevice = device
            DispatchQueue.main.async {
                self.currentZoom = 1.0
            }
        }

        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
        }
        session.commitConfiguration()
    }

    func setZoom(factor: Double) {
        guard let device = currentDevice else { return }
        let clamped = max(device.minAvailableVideoZoomFactor, min(factor, min(device.maxAvailableVideoZoomFactor, 8.0)))
        do {
            try device.lockForConfiguration()
            device.videoZoomFactor = clamped
            device.unlockForConfiguration()
            DispatchQueue.main.async {
                self.currentZoom = clamped
            }
        } catch {}
    }

    func switchCamera() {
        isUsingFrontCamera.toggle()
        let position: AVCaptureDevice.Position = isUsingFrontCamera ? .front : .back
        sessionQueue.async { [weak self] in
            self?.configureSession(position: position)
        }
    }

    func capturePhoto(completion: @escaping @MainActor @Sendable (Data?) -> Void) {
        let mode = flashMode
        sessionQueue.async { [weak self] in
            guard let self else { return }
            self.photoCaptureCompletion = completion
            let settings = AVCapturePhotoSettings()
            if self.photoOutput.supportedFlashModes.contains(mode) {
                settings.flashMode = mode
            }
            self.photoOutput.capturePhoto(with: settings, delegate: self)
        }
    }
}

extension CameraCaptureController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        let data = photo.fileDataRepresentation()
        let completion = photoCaptureCompletion
        photoCaptureCompletion = nil
        Task { @MainActor in
            completion?(data)
        }
    }
}
#endif
