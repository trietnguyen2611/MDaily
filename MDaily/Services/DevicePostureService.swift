import Foundation
import CoreGraphics
import Combine

#if canImport(UIKit)
import UIKit
#endif

public enum AdaptiveLayoutProfile: String, CaseIterable, Identifiable, Sendable {
    case iPhoneDuoFolded
    case iPhoneDuoUnfolded
    case standardPhone
    case pad
    case mac

    public var id: String { rawValue }

    public var usesRightVerticalRail: Bool {
        self == .iPhoneDuoFolded || self == .iPhoneDuoUnfolded
    }

    public var supportsInlineInspector: Bool {
        self == .iPhoneDuoUnfolded || self == .pad || self == .mac
    }
}

@MainActor
public final class DevicePostureService: ObservableObject {
    public static let shared = DevicePostureService()

    public let hardwareModelIdentifier: String
    public let simulatorDeviceName: String?

    private init() {
        let env = ProcessInfo.processInfo.environment
        self.simulatorDeviceName = env["SIMULATOR_DEVICE_NAME"]

        if let simModel = env["SIMULATOR_MODEL_IDENTIFIER"], !simModel.isEmpty {
            self.hardwareModelIdentifier = simModel
        } else {
            var sysinfo = utsname()
            uname(&sysinfo)
            let machine = withUnsafePointer(to: &sysinfo.machine) { ptr in
                ptr.withMemoryRebound(to: CChar.self, capacity: Int(_SYS_NAMELEN)) { cPtr in
                    String(cString: cPtr)
                }
            }
            self.hardwareModelIdentifier = machine
        }
    }

    public var isIPhoneDuoHardware: Bool {
        if hardwareModelIdentifier == "iPhone19,4" {
            return true
        }
        if let simName = simulatorDeviceName,
           simName.localizedCaseInsensitiveContains("Duo") {
            return true
        }
        return false
    }

    public func resolveProfile(for windowSize: CGSize) -> AdaptiveLayoutProfile {
        #if os(macOS)
        return .mac
        #elseif os(iOS)
        if isIPhoneDuoHardware {
            return windowSize.width >= 650 ? .iPhoneDuoUnfolded : .iPhoneDuoFolded
        }
        if UIDevice.current.userInterfaceIdiom == .pad {
            return .pad
        }
        return .standardPhone
        #else
        return .mac
        #endif
    }
}
