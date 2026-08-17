import Foundation
import Capacitor

#if canImport(FoundationModels)
import FoundationModels
#endif

@objc(AFMPlugin)
public class AFMPlugin: CAPPlugin, CAPBridgedPlugin {
    public let identifier = "AFMPlugin"
    public let jsName = "AFMPlugin"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "isAFMAvailable", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "generateText", returnType: CAPPluginReturnPromise)
    ]

    @objc func isAFMAvailable(_ call: CAPPluginCall) {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            let model = SystemLanguageModel.default

            switch model.availability {
            case .available:
                call.resolve([
                    "available": true,
                    "model": "Apple Foundation Model (On-Device)"
                ])
            case .unavailable(let reason):
                var reasonText = "Không khả dụng"
                switch reason {
                case .deviceNotEligible:
                    reasonText = "Thiết bị không hỗ trợ Apple Intelligence"
                case .appleIntelligenceNotEnabled:
                    reasonText = "Apple Intelligence chưa được bật trong Cài đặt"
                case .modelNotReady:
                    reasonText = "Model đang tải xuống, vui lòng thử lại sau"
                @unknown default:
                    reasonText = "Không khả dụng (lý do không xác định)"
                }
                call.resolve([
                    "available": false,
                    "model": reasonText
                ])
            @unknown default:
                call.resolve([
                    "available": false,
                    "model": "Trạng thái không xác định"
                ])
            }
        } else {
            call.resolve([
                "available": false,
                "model": "Cần iOS 26+ để sử dụng Apple Foundation Models"
            ])
        }
        #else
        call.resolve([
            "available": false,
            "model": "SDK chưa hỗ trợ FoundationModels (cần Xcode 26+)"
        ])
        #endif
    }

    @objc func generateText(_ call: CAPPluginCall) {
        guard let prompt = call.getString("prompt") else {
            call.reject("Prompt is required")
            return
        }
        let systemPrompt = call.getString("systemPrompt") ?? ""
        let context = call.getString("context") ?? ""

        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            let model = SystemLanguageModel.default
            guard model.isAvailable else {
                let reply = self.localFallback(prompt: prompt, context: context)
                call.resolve(["text": reply, "engine": "Local Fallback (model not available)"])
                return
            }

            Task {
                do {
                    // Build system instructions
                    var instructions = systemPrompt
                    if !context.isEmpty {
                        instructions += "\n\nDữ liệu chi tiêu của người dùng:\n\(context)"
                    }

                    // Create session with instructions — model defaults to .default
                    let session = LanguageModelSession(instructions: instructions)

                    // Send user prompt and get response
                    let response = try await session.respond(to: prompt)

                    await MainActor.run {
                        call.resolve([
                            "text": response.content,
                            "engine": "Apple Foundation Model (On-Device)"
                        ])
                    }
                } catch {
                    let reply = self.localFallback(prompt: prompt, context: context)
                    await MainActor.run {
                        call.resolve([
                            "text": reply,
                            "engine": "Local Fallback (AFM error: \(error.localizedDescription))"
                        ])
                    }
                }
            }
            return
        }
        #endif

        // Fallback for older iOS or missing framework
        DispatchQueue.global(qos: .userInitiated).async {
            let reply = self.localFallback(prompt: prompt, context: context)
            DispatchQueue.main.async {
                call.resolve([
                    "text": reply,
                    "engine": "Local Fallback"
                ])
            }
        }
    }

    // MARK: - Local Fallback
    private func localFallback(prompt: String, context: String) -> String {
        let p = prompt.lowercased()
        
        if p.contains("tổng") || p.contains("bao nhiêu") || p.contains("tổng cộng") {
            if context.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return "Mày chưa lưu khoản chi tiêu nào cả! Giữ phong độ quản lý tài chính nhé."
            }
            return "Dữ liệu chi tiêu của mày:\n\n\(context)\n\nHãy chú ý kiểm tra lại các khoản chi lớn để điều chỉnh ngân sách nhé!"
        }
        
        if p.contains("khuyên") || p.contains("tiết kiệm") || p.contains("lời khuyên") {
            return "Lời khuyên: Đặt hạn mức chi tiêu mỗi ngày, bớt vung tay săn sale và ghi chép đầy đủ vào MDaily ngay khi vừa tiêu tiền."
        }
        
        if p.contains("ăn") || p.contains("uống") || p.contains("trà sữa") {
            return "Chi cho ăn uống là thiết yếu, nhưng nhớ đừng 'vung tay quá trán' đầu tháng để rồi cuối tháng ăn mì gói nhé!"
        }
        
        if p.contains("chào") || p.contains("hi") || p.contains("hello") {
            return "Chào mày! Tao là MDaily AI. Hôm nay mày lỡ vung tiền vào cái gì rồi? Khai ra mau!"
        }
        
        return "MDaily AI đã tiếp nhận yêu cầu: \"\(prompt)\". Dữ liệu tài chính được bảo mật 100% trên thiết bị."
    }
}
