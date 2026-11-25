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

    public func displayName(lang: Language) -> String {
        switch self {
        case .iPhoneDuoFolded: return LocalizationService.t("layout_duo_folded", lang: lang)
        case .iPhoneDuoUnfolded: return LocalizationService.t("layout_duo_unfolded", lang: lang)
        case .standardPhone: return LocalizationService.t("layout_standard_phone", lang: lang)
        case .pad: return LocalizationService.t("layout_pad", lang: lang)
        case .mac: return LocalizationService.t("layout_mac", lang: lang)
        }
    }
}

@MainActor
public final class DevicePostureService: ObservableObject {
    public static let shared = DevicePostureService()

    @Published public var overrideProfile: AdaptiveLayoutProfile? = nil

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

        let args = ProcessInfo.processInfo.arguments
        if let flagIdx = args.firstIndex(of: "-mdaily-profile"),
           flagIdx + 1 < args.count,
           let profile = AdaptiveLayoutProfile(rawValue: args[flagIdx + 1]) {
            self.overrideProfile = profile
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

    public var hardwareDisplayName: String {
        if isIPhoneDuoHardware {
            return "\(hardwareModelIdentifier) (iPhone Duo)"
        }
        #if os(macOS)
        return "macOS (\(hardwareModelIdentifier))"
        #else
        if let simName = simulatorDeviceName, !simName.isEmpty {
            return "\(simName) (\(hardwareModelIdentifier))"
        }
        return hardwareModelIdentifier
        #endif
    }

    public func resolveProfile(for windowSize: CGSize) -> AdaptiveLayoutProfile {
        if let overrideProfile {
            return overrideProfile
        }

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
